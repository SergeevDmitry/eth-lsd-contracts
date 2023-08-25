pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INodeDeposit.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/INetworkProposal.sol";
import "./interfaces/IProposalType.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NodeDeposit is INodeDeposit, IProposalType {
    using EnumerableSet for EnumerableSet.UintSet;

    bool public initialized;
    bool public lightNodeDepositEnabled;
    bool public superNodeDepositEnabled;

    uint256 public lightNodeDepositAmount;

    address public userDepositAddress;
    address public ethDepositAddress;
    address public networkProposalAddress;

    bytes public withdrawCredentials;

    mapping(bytes => Pubkey) public pubkeyOf;
    mapping(address => bool) isSuperNode;

    modifier onlyVoter() {
        require(INetworkProposal(networkProposalAddress).isVoter(msg.sender), "not voter");
        _;
    }

    modifier onlyAdmin() {
        require(INetworkProposal(networkProposalAddress).isAdmin(msg.sender), "not admin");
        _;
    }

    function init(
        address _userDepositAddress,
        address _ethDepositAddress,
        address _networkProposalAddress,
        bytes calldata _withdrawCredentials
    ) external override {
        require(!initialized, "already initizlized");

        initialized = true;
        lightNodeDepositEnabled = true;
        superNodeDepositEnabled = true;

        userDepositAddress = _userDepositAddress;
        ethDepositAddress = _ethDepositAddress;
        networkProposalAddress = _networkProposalAddress;
        withdrawCredentials = _withdrawCredentials;
    }

    // ------------ settings ------------

    function setNodePubkeyStatus(bytes calldata _validatorPubkey, PubkeyStatus _status) public onlyAdmin {
        require(pubkeyOf[_validatorPubkey]._status != PubkeyStatus.UnInitial, "pubkey not exist");

        _setNodePubkeyStatus(_validatorPubkey, _status);
    }

    function setLightNodeDepositEnabled(bool _value) public onlyAdmin {
        lightNodeDepositEnabled = _value;
    }

    function setSuperNodeDepositEnabled(bool _value) public onlyAdmin {
        superNodeDepositEnabled = _value;
    }

    function setLightNodeDepositAmount(uint256 _amount) public onlyAdmin {
        lightNodeDepositAmount = _amount;
    }

    function setWithdrawCredentials(bytes calldata _withdrawCredentials) public onlyAdmin {
        withdrawCredentials = _withdrawCredentials;
    }

    function addSuperNode(address _superNodeAddress) public onlyAdmin {
        isSuperNode[_superNodeAddress] = true;
    }

    function removeSuperNode(address _superNodeAddress) public onlyAdmin {
        delete isSuperNode[_superNodeAddress];
    }

    // ------------ node ------------

    function deposit(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external payable override {
        require(
            _validatorPubkeys.length == _validatorSignatures.length &&
                _validatorPubkeys.length == _depositDataRoots.length,
            "params len err"
        );

        NodeType nodeType = NodeType.Undefined;
        uint256 depositAmount;
        uint256 nodeDepositAmount;
        if (isSuperNode[msg.sender]) {
            require(superNodeDepositEnabled, "super node deposits disabled");
            require(msg.value == 0, "msg value not match");

            nodeType = NodeType.SuperNode;
            depositAmount = uint256(1 ether);
        } else {
            require(lightNodeDepositEnabled, "light node deposits disabled");
            require(msg.value == _validatorPubkeys.length * lightNodeDepositAmount, "msg value not match");

            nodeType = NodeType.LightNode;
            depositAmount = lightNodeDepositAmount;
            nodeDepositAmount = lightNodeDepositAmount;
        }

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _deposit(
                _validatorPubkeys[i],
                _validatorSignatures[i],
                _depositDataRoots[i],
                nodeType,
                nodeDepositAmount,
                depositAmount
            );
        }
    }

    function stake(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external override {
        require(
            _validatorPubkeys.length == _validatorSignatures.length &&
                _validatorPubkeys.length == _depositDataRoots.length,
            "params len err"
        );

        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _stake(_validatorPubkeys[i], _validatorSignatures[i], _depositDataRoots[i]);
        }
    }

    function offBoard(bytes calldata _validatorPubkey) external override {
        setAndCheckNodePubkeyInOffBoard(_validatorPubkey);

        emit OffBoarded(msg.sender, _validatorPubkey);
    }

    function provideNodeDepositToken(bytes calldata _validatorPubkey) external payable override {
        Pubkey memory pubkey = pubkeyOf[_validatorPubkey];

        require(pubkey._status == PubkeyStatus.Offboard, "pubkey status unmatch");
        require(msg.value == pubkey._nodeDepositAmount, "msg value not match");

        _setNodePubkeyStatus(_validatorPubkey, PubkeyStatus.CanWithdraw);
    }

    function withdrawNodeDepositToken(bytes calldata _validatorPubkey) external override {
        Pubkey memory pubkey = pubkeyOf[_validatorPubkey];

        require(pubkey._status == PubkeyStatus.CanWithdraw, "pubkey status unmatch");
        require(msg.sender == pubkey._owner, "not pubkey owner");

        // set pubkey status
        _setNodePubkeyStatus(_validatorPubkey, PubkeyStatus.Withdrawed);

        (bool success, ) = (msg.sender).call{value: pubkey._nodeDepositAmount}("");
        require(success, "transferr failed");
    }

    // ------------ voter ------------

    // Only accepts calls from trusted (oracle) nodes
    function voteWithdrawCredentials(bytes[] calldata _pubkeys, bool[] calldata _matchs) external override onlyVoter {
        require(_pubkeys.length == _matchs.length, "params len err");

        for (uint256 i = 0; i < _pubkeys.length; i++) {
            _voteWithdrawCredentials(_pubkeys[i], _matchs[i]);
        }
    }

    // ------------ network ------------

    // Deposit ETH from deposit pool
    // Only accepts calls from the UserDeposit contract
    function depositEth() external payable override {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // ------------ helper ------------
    function _deposit(
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot,
        NodeType _nodeType,
        uint256 _nodeDepositAmount,
        uint256 _depositAmount
    ) private {
        setAndCheckNodePubkeyInDeposit(_validatorPubkey, _nodeType, _nodeDepositAmount);

        IDepositContract(ethDepositAddress).deposit{value: _depositAmount}(
            _validatorPubkey,
            withdrawCredentials,
            _validatorSignature,
            _depositDataRoot
        );

        emit Deposited(msg.sender, _nodeType, _validatorPubkey, _validatorSignature, _depositAmount);
    }

    function _stake(
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    ) private {
        setAndCheckNodePubkeyInStake(_validatorPubkey);

        Pubkey memory pubkey = pubkeyOf[_validatorPubkey];

        uint256 willWithdrawAmount;
        if (pubkey._nodeType == NodeType.LightNode) {
            willWithdrawAmount = uint256(32 ether) - pubkey._nodeDepositAmount;
        } else {
            willWithdrawAmount = uint256(31 ether);
        }

        IUserDeposit(userDepositAddress).withdrawExcessBalanceForNodeDeposit(willWithdrawAmount);

        IDepositContract(ethDepositAddress).deposit{value: willWithdrawAmount}(
            _validatorPubkey,
            withdrawCredentials,
            _validatorSignature,
            _depositDataRoot
        );

        emit Staked(msg.sender, _validatorPubkey);
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInDeposit(
        bytes calldata _pubkey,
        NodeType _nodeType,
        uint256 _nodeDepositAmount
    ) private {
        require(pubkeyOf[_pubkey]._status == PubkeyStatus.UnInitial, "pubkey already exists");

        // add pubkey
        pubkeyOf[_pubkey] = Pubkey({
            _nodeType: _nodeType,
            _status: PubkeyStatus.Initial,
            _owner: msg.sender,
            _nodeDepositAmount: _nodeDepositAmount
        });
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInStake(bytes calldata _pubkey) private {
        // check status
        require(pubkeyOf[_pubkey]._status == PubkeyStatus.Match, "pubkey status unmatch");
        // check owner
        require(pubkeyOf[_pubkey]._owner == msg.sender, "not pubkey owner");

        // set pubkey status
        _setNodePubkeyStatus(_pubkey, PubkeyStatus.Staking);
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInOffBoard(bytes calldata _pubkey) private {
        Pubkey memory pubkey = pubkeyOf[_pubkey];

        require(pubkey._nodeType == NodeType.LightNode, "not light node");
        require(pubkey._status == PubkeyStatus.Match, "pubkey status unmatch");
        require(pubkey._owner == msg.sender, "not pubkey owner");

        // set pubkey status
        _setNodePubkeyStatus(_pubkey, PubkeyStatus.Offboard);
    }

    function _voteWithdrawCredentials(bytes calldata _pubkey, bool _match) private {
        bytes32 proposalId = keccak256(abi.encodePacked("voteWithdrawCredentials", _pubkey));
        (Proposal memory proposal, uint8 threshold) = INetworkProposal(networkProposalAddress).checkProposal(
            proposalId
        );

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            _setNodePubkeyStatus(_pubkey, _match ? PubkeyStatus.Match : PubkeyStatus.UnMatch);

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId);
        }

        INetworkProposal(networkProposalAddress).saveProposal(proposalId, proposal);
    }

    // Set a light node pubkey status
    function _setNodePubkeyStatus(bytes calldata _validatorPubkey, PubkeyStatus _status) private {
        pubkeyOf[_validatorPubkey]._status = _status;

        emit SetPubkeyStatus(_validatorPubkey, _status);
    }
}
