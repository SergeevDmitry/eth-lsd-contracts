pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INodeDeposit.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/INetworkProposal.sol";

contract NodeDeposit is INodeDeposit {
    bool public initialized;
    uint8 public version;

    bool public lightNodeDepositEnabled;
    bool public trustNodeDepositEnabled;

    uint256 public lightNodeDepositAmount;
    uint256 public trustNodePubkeyNumberLimit;

    address public userDepositAddress;
    address public ethDepositAddress;
    address public networkProposalAddress;

    bytes public withdrawCredentials;

    bytes[] public pubkeys;
    mapping(bytes => PubkeyInfo) public pubkeyInfoOf;
    mapping(address => NodeInfo) public nodeInfoOf; //light node and trust node are always mutually exclusive and cannot be converted to each other

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
        version = 1;
        lightNodeDepositEnabled = true;
        trustNodeDepositEnabled = true;
        trustNodePubkeyNumberLimit = 100;

        userDepositAddress = _userDepositAddress;
        ethDepositAddress = _ethDepositAddress;
        networkProposalAddress = _networkProposalAddress;
        withdrawCredentials = _withdrawCredentials;
    }

    // ------------ getter ------------

    function getPubkeysLength() public view returns (uint256) {
        return pubkeys.length;
    }

    function getPubkeys(uint256 _start, uint256 _end) public view returns (bytes[] memory pubkeyList) {
        pubkeyList = new bytes[](_end - _start);
        uint256 i = _start;
        uint256 j;
        for (; i < _end; ) {
            pubkeyList[j] = pubkeys[j];
            i++;
            j++;
        }
        return pubkeyList;
    }

    // ------------ settings ------------

    function setNodePubkeyStatus(bytes calldata _validatorPubkey, PubkeyStatus _status) public onlyAdmin {
        require(pubkeyInfoOf[_validatorPubkey]._status != PubkeyStatus.UnInitial, "pubkey not exist");

        _setNodePubkeyStatus(_validatorPubkey, _status);
    }

    function setLightNodeDepositEnabled(bool _value) public onlyAdmin {
        lightNodeDepositEnabled = _value;
    }

    function setTrustNodeDepositEnabled(bool _value) public onlyAdmin {
        trustNodeDepositEnabled = _value;
    }

    function setLightNodeDepositAmount(uint256 _amount) public onlyAdmin {
        lightNodeDepositAmount = _amount;
    }

    function setTrustNodePubkeyLimit(uint256 _value) public onlyAdmin {
        trustNodePubkeyNumberLimit = _value;
    }

    function setWithdrawCredentials(bytes calldata _withdrawCredentials) public onlyAdmin {
        withdrawCredentials = _withdrawCredentials;
    }

    function addTrustNode(address _trustNodeAddress) public onlyAdmin {
        require(nodeInfoOf[_trustNodeAddress]._nodeType == NodeType.Undefined, "already exist");

        nodeInfoOf[_trustNodeAddress] = NodeInfo({_nodeType: NodeType.TrustNode, _removed: false, _pubkeyNumber: 0});
    }

    function removeTrustNode(address _trustNodeAddress) public onlyAdmin {
        require(nodeInfoOf[_trustNodeAddress]._nodeType == NodeType.TrustNode, "already exist");

        nodeInfoOf[_trustNodeAddress]._removed = true;
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

        NodeInfo memory node = nodeInfoOf[msg.sender];
        if (node._nodeType == NodeType.Undefined) {
            node._nodeType = NodeType.LightNode;
        }

        uint256 depositAmount;
        uint256 nodeDepositAmount;
        if (node._nodeType == NodeType.TrustNode) {
            require(!node._removed, "already removed");
            require(trustNodeDepositEnabled, "trust node deposits disabled");
            require(msg.value == 0, "msg value not match");
            require(node._pubkeyNumber < trustNodePubkeyNumberLimit, "pubkey number limit");

            depositAmount = uint256(1 ether);

            IUserDeposit(userDepositAddress).withdrawExcessBalance(depositAmount * _validatorPubkeys.length);
        } else {
            require(lightNodeDepositEnabled, "light node deposits disabled");
            require(msg.value == _validatorPubkeys.length * lightNodeDepositAmount, "msg value not match");

            depositAmount = lightNodeDepositAmount;
            nodeDepositAmount = lightNodeDepositAmount;
        }

        node._pubkeyNumber += _validatorPubkeys.length;

        // update node
        nodeInfoOf[msg.sender] = node;

        // deposit
        for (uint256 i = 0; i < _validatorPubkeys.length; i++) {
            _deposit(
                _validatorPubkeys[i],
                _validatorSignatures[i],
                _depositDataRoots[i],
                node._nodeType,
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

    // ------------ voter ------------

    // Only accepts calls from trusted (oracle) nodes
    function voteWithdrawCredentials(bytes[] calldata _pubkeys, bool[] calldata _matchs) external override {
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
        require(pubkeyInfoOf[_validatorPubkey]._status == PubkeyStatus.UnInitial, "pubkey already exists");
        pubkeys.push(_validatorPubkey);

        // add pubkey
        pubkeyInfoOf[_validatorPubkey] = PubkeyInfo({
            _status: PubkeyStatus.Deposited,
            _owner: msg.sender,
            _nodeDepositAmount: _nodeDepositAmount,
            _depositBlock: block.number,
            _depositSignature: _validatorSignature
        });

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
        PubkeyInfo memory pubkeyInfo = pubkeyInfoOf[_validatorPubkey];

        require(pubkeyInfo._status == PubkeyStatus.Match, "pubkey status unmatch");
        require(pubkeyInfo._owner == msg.sender, "not pubkey owner");

        _setNodePubkeyStatus(_validatorPubkey, PubkeyStatus.Staked);

        uint256 willWithdrawAmount;
        NodeType nodeType = nodeInfoOf[pubkeyInfo._owner]._nodeType;
        if (nodeType == NodeType.LightNode) {
            willWithdrawAmount = uint256(32 ether) - pubkeyInfo._nodeDepositAmount;
        } else if (nodeType == NodeType.TrustNode) {
            willWithdrawAmount = uint256(31 ether);
        } else {
            revert("unknown type");
        }

        IUserDeposit(userDepositAddress).withdrawExcessBalance(willWithdrawAmount);

        IDepositContract(ethDepositAddress).deposit{value: willWithdrawAmount}(
            _validatorPubkey,
            withdrawCredentials,
            _validatorSignature,
            _depositDataRoot
        );

        emit Staked(msg.sender, _validatorPubkey);
    }

    function _voteWithdrawCredentials(bytes calldata _pubkey, bool _match) private {
        bytes32 proposalId = keccak256(abi.encodePacked("voteWithdrawCredentials", _pubkey));

        // Finalize if Threshold has been reached
        if (INetworkProposal(networkProposalAddress).shouldExecute(proposalId, msg.sender)) {
            _setNodePubkeyStatus(_pubkey, _match ? PubkeyStatus.Match : PubkeyStatus.UnMatch);
        }
    }

    // Set node pubkey status
    function _setNodePubkeyStatus(bytes calldata _validatorPubkey, PubkeyStatus _status) private {
        pubkeyInfoOf[_validatorPubkey]._status = _status;

        emit SetPubkeyStatus(_validatorPubkey, _status);
    }
}
