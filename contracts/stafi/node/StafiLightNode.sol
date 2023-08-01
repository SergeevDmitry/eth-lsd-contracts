pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/node/IStafiLightNode.sol";
import "../interfaces/node/IStafiNodeManager.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../interfaces/storage/IPubkeySetStorage.sol";
import "../../project/interfaces/IProjLightNode.sol";
import "../../project/interfaces/IProjNodeManager.sol";
import "../../project/interfaces/IProjSettings.sol";
import "../../project/interfaces/IProjUserDeposit.sol";

contract StafiLightNode is StafiBase, IStafiLightNode {
    // Libs
    using SafeMath for uint256;

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Deposited(
        address node,
        bytes pubkey,
        bytes validatorSignature,
        uint256 amount
    );
    event Staked(address node, bytes pubkey);
    event OffBoarded(address node, bytes pubkey);
    event SetPubkeyStatus(bytes pubkey, uint256 status);

    uint256 public constant PUBKEY_STATUS_UNINITIAL = 0;
    uint256 public constant PUBKEY_STATUS_INITIAL = 1;
    uint256 public constant PUBKEY_STATUS_MATCH = 2;
    uint256 public constant PUBKEY_STATUS_STAKING = 3;
    uint256 public constant PUBKEY_STATUS_UNMATCH = 4;
    uint256 public constant PUBKEY_STATUS_OFFBOARD = 5;
    uint256 public constant PUBKEY_STATUS_CANWITHDRAW = 6; // can withdraw node deposit amount after offboard
    uint256 public constant PUBKEY_STATUS_WITHDRAWED = 7;

    // Construct
    constructor(
        address _stafiStorageAddress
    ) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth()
        external
        payable
        override
        onlyLatestContract(1, "stafiUserDeposit", msg.sender)
    {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function PubkeySetStorage() public view returns (IPubkeySetStorage) {
        return IPubkeySetStorage(getContractAddress(1, "pubkeySetStorage"));
    }

    function ProjSettings(uint256 _pId) private view returns (IProjSettings) {
        return IProjSettings(getContractAddress(_pId, "projSettings"));
    }

    // Get the number of pubkeys owned by a light node
    function getLightNodePubkeyCount(
        uint256 _pId,
        address _nodeAddress
    ) public view returns (uint256) {
        return
            PubkeySetStorage().getCount(
                keccak256(
                    abi.encodePacked(
                        "lightNode.pubkeys.index",
                        _pId,
                        _nodeAddress
                    )
                )
            );
    }

    // Get a light node pubkey by index
    function getLightNodePubkeyAt(
        uint256 _pId,
        address _nodeAddress,
        uint256 _index
    ) public view returns (bytes memory) {
        return
            PubkeySetStorage().getItem(
                keccak256(
                    abi.encodePacked(
                        "lightNode.pubkeys.index",
                        _pId,
                        _nodeAddress
                    )
                ),
                _index
            );
    }

    // Get a light node pubkey status
    function getLightNodePubkeyStatus(
        uint256 _pId,
        bytes calldata _validatorPubkey
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "lightNode.pubkey.status",
                        _pId,
                        _validatorPubkey
                    )
                )
            );
    }

    // Set a light node pubkey status
    function _setLightNodePubkeyStatus(
        uint256 _pId,
        bytes calldata _validatorPubkey,
        uint256 _status
    ) private {
        setUint(
            keccak256(
                abi.encodePacked(
                    "lightNode.pubkey.status",
                    _pId,
                    _validatorPubkey
                )
            ),
            _status
        );

        emit SetPubkeyStatus(_validatorPubkey, _status);
    }

    function setLightNodePubkeyStatus(
        uint256 _pId,
        bytes calldata _validatorPubkey,
        uint256 _status
    ) public onlySuperUser(1) {
        _setLightNodePubkeyStatus(_pId, _validatorPubkey, _status);
    }

    function getPubkeyVoted(
        uint256 _pId,
        bytes calldata _validatorPubkey,
        address user
    ) public view returns (bool) {
        return
            getBool(
                keccak256(
                    abi.encodePacked(
                        "lightNode.memberVotes.",
                        _pId,
                        _validatorPubkey,
                        user
                    )
                )
            );
    }

    function getSuperNodePublicKeyStatus(
        uint256 _pId,
        bytes calldata _pubkey
    ) private view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked("superNode.pubkey.status", _pId, _pubkey)
                )
            );
    }

    function getPubkeyIndex(
        uint256 _pId,
        address _user,
        bytes calldata _pubkey
    ) public view returns (int256) {
        return
            PubkeySetStorage().getIndexOf(
                keccak256(
                    abi.encodePacked("lightNode.pubkeys.index", _pId, _user)
                ),
                _pubkey
            );
    }

    function deposit(
        address _user,
        uint256 _value,
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external override onlyLatestContract(1, "stafiLightNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projLightNode") == msg.sender,
            "Invalid caller"
        );
        IProjLightNode projLightNode = IProjLightNode(msg.sender);
        require(
            ProjSettings(_pId).getLightNodeDepositEnabled(),
            "light node deposits are currently disabled"
        );
        uint256 len = _validatorPubkeys.length;
        require(
            len == _validatorSignatures.length &&
                len == _depositDataRoots.length,
            "params len err"
        );
        require(
            _value == len.mul(ProjSettings(_pId).getCurrentNodeDepositAmount()),
            "msg value not match"
        );

        for (uint256 i = 0; i < len; i++) {
            _deposit(
                _pId,
                _user,
                _validatorPubkeys[i],
                _validatorSignatures[i],
                _depositDataRoots[i]
            );
        }
    }

    function stake(
        address _user,
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external override onlyLatestContract(1, "stafiLightNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projLightNode") == msg.sender,
            "Invalid caller"
        );
        require(
            _validatorPubkeys.length == _validatorSignatures.length &&
                _validatorPubkeys.length == _depositDataRoots.length,
            "params len err"
        );
        IProjLightNode projLightNode = IProjLightNode(msg.sender);
        // Load contracts
        IProjUserDeposit projUserDeposit = IProjUserDeposit(
            getContractAddress(_pId, "projUserDeposit")
        );
        projUserDeposit.withdrawExcessBalanceForLightNode(
            _validatorPubkeys.length.mul(
                uint256(32 ether).sub(
                    ProjSettings(_pId).getCurrentNodeDepositAmount()
                )
            )
        );

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _stake(
                _pId,
                _user,
                _validatorPubkeys[i],
                _validatorSignatures[i],
                _depositDataRoots[i]
            );
        }
    }

    function offBoard(
        address _user,
        bytes calldata _validatorPubkey
    ) external override onlyLatestContract(1, "stafiLightNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projLightNode") == msg.sender,
            "Invalid caller"
        );
        setAndCheckNodePubkeyInOffBoard(_pId, _user, _validatorPubkey);

        emit OffBoarded(msg.sender, _validatorPubkey);
    }

    function provideNodeDepositToken(
        uint256 _value,
        bytes calldata _validatorPubkey
    )
        external
        payable
        override
        onlyLatestContract(1, "stafiLightNode", address(this))
    {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projLightNode") == msg.sender,
            "Invalid caller"
        );
        IProjLightNode projLightNode = IProjLightNode(msg.sender);
        require(
            _value == ProjSettings(_pId).getCurrentNodeDepositAmount(),
            "msg value not match"
        );
        // check status
        require(
            getLightNodePubkeyStatus(_pId, _validatorPubkey) ==
                PUBKEY_STATUS_OFFBOARD,
            "pubkey status unmatch"
        );

        projLightNode.provideEther(_value);

        // set pubkey status
        _setLightNodePubkeyStatus(
            _pId,
            _validatorPubkey,
            PUBKEY_STATUS_CANWITHDRAW
        );
    }

    function withdrawNodeDepositToken(
        address _user,
        bytes calldata _validatorPubkey
    ) external override onlyLatestContract(1, "stafiLightNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projLightNode") == msg.sender,
            "Invalid caller"
        );
        IProjLightNode projLightNode = IProjLightNode(msg.sender);
        // check status
        require(
            getLightNodePubkeyStatus(_pId, _validatorPubkey) ==
                PUBKEY_STATUS_CANWITHDRAW,
            "pubkey status unmatch"
        );

        // check owner
        require(
            getPubkeyIndex(_pId, _user, _validatorPubkey) >= 0,
            "not pubkey owner"
        );

        // set pubkey status
        _setLightNodePubkeyStatus(
            _pId,
            _validatorPubkey,
            PUBKEY_STATUS_WITHDRAWED
        );

        projLightNode.withdrawEther(_user);
    }

    function _deposit(
        uint256 _pId,
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    ) private {
        setAndCheckNodePubkeyInDeposit(_pId, _user, _validatorPubkey);
        IProjLightNode projLightNode = IProjLightNode(msg.sender);
        projLightNode.ethDeposit(
            _user,
            _validatorPubkey,
            _validatorSignature,
            _depositDataRoot
        );
    }

    function _stake(
        uint256 _pId,
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    ) private {
        setAndCheckNodePubkeyInStake(_pId, _user, _validatorPubkey);
        IProjLightNode projLightNode = IProjLightNode(
            getContractAddress(_pId, "projLightNode")
        );
        projLightNode.ethStake(
            _user,
            _validatorPubkey,
            _validatorSignature,
            _depositDataRoot
        );
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInDeposit(
        uint256 _pId,
        address _user,
        bytes calldata _pubkey
    ) private {
        // check pubkey of superNodes
        require(
            getSuperNodePublicKeyStatus(_pId, _pubkey) ==
                PUBKEY_STATUS_UNINITIAL,
            "super Node pubkey exists"
        );
        // check status
        require(
            getLightNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_UNINITIAL,
            "pubkey status unmatch"
        );
        // set pubkey status
        _setLightNodePubkeyStatus(_pId, _pubkey, PUBKEY_STATUS_INITIAL);
        // add pubkey to set
        PubkeySetStorage().addItem(
            keccak256(abi.encodePacked("lightNode.pubkeys.index", _pId, _user)),
            _pubkey
        );
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInStake(
        uint256 _pId,
        address _user,
        bytes calldata _pubkey
    ) private {
        // check status
        require(
            getLightNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_MATCH,
            "pubkey status unmatch"
        );
        // check owner
        require(getPubkeyIndex(_pId, _user, _pubkey) >= 0, "not pubkey owner");

        // set pubkey status
        _setLightNodePubkeyStatus(_pId, _pubkey, PUBKEY_STATUS_STAKING);
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInOffBoard(
        uint256 _pId,
        address _user,
        bytes calldata _pubkey
    ) private {
        // check status
        require(
            getLightNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_MATCH,
            "pubkey status unmatch"
        );
        // check owner
        require(
            PubkeySetStorage().getIndexOf(
                keccak256(
                    abi.encodePacked("lightNode.pubkeys.index", _pId, _user)
                ),
                _pubkey
            ) >= 0,
            "not pubkey owner"
        );

        // set pubkey status
        _setLightNodePubkeyStatus(_pId, _pubkey, PUBKEY_STATUS_OFFBOARD);
    }

    // Only accepts calls from trusted (oracle) nodes
    function voteWithdrawCredentials(
        address _voter,
        bytes[] calldata _pubkeys,
        bool[] calldata _matchs
    ) external override onlyLatestContract(1, "stafiLightNode", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projLightNode") == msg.sender,
            "Invalid caller"
        );
        require(_pubkeys.length == _matchs.length, "params len err");
        for (uint256 i = 0; i < _pubkeys.length; i++) {
            _voteWithdrawCredentials(_pId, _voter, _pubkeys[i], _matchs[i]);
        }
    }

    function _voteWithdrawCredentials(
        uint256 _pId,
        address _voter,
        bytes calldata _pubkey,
        bool _match
    ) private {
        // Check & update node vote status
        require(
            !getBool(
                keccak256(
                    abi.encodePacked(
                        "lightNode.memberVotes.",
                        _pId,
                        _pubkey,
                        _voter
                    )
                )
            ),
            "Member has already voted to withdrawCredentials"
        );
        setBool(
            keccak256(
                abi.encodePacked(
                    "lightNode.memberVotes.",
                    _pId,
                    _pubkey,
                    _voter
                )
            ),
            true
        );

        // Increment votes count
        uint256 totalVotes = getUint(
            keccak256(
                abi.encodePacked("lightNode.totalVotes", _pId, _pubkey, _match)
            )
        );
        totalVotes = totalVotes.add(1);
        setUint(
            keccak256(
                abi.encodePacked("lightNode.totalVotes", _pId, _pubkey, _match)
            ),
            totalVotes
        );

        // Check count and set status
        uint256 calcBase = 1 ether;
        IProjNodeManager projNodeManager = IProjNodeManager(
            getContractAddress(_pId, "stafiNodeManager")
        );
        IProjSettings projSettings = IProjSettings(
            getContractAddress(_pId, "projSettings")
        );
        if (
            getLightNodePubkeyStatus(_pId, _pubkey) == PUBKEY_STATUS_INITIAL &&
            calcBase.mul(totalVotes) >=
            projNodeManager.getTrustedNodeCount().mul(
                projSettings.getNodeConsensusThreshold()
            )
        ) {
            _setLightNodePubkeyStatus(
                _pId,
                _pubkey,
                _match ? PUBKEY_STATUS_MATCH : PUBKEY_STATUS_UNMATCH
            );
        }
    }
}
