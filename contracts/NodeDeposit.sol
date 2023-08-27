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
            require(trustNodeDepositEnabled, "super node deposits disabled");
            require(msg.value == 0, "msg value not match");
            require(node._pubkeyNumber < trustNodePubkeyNumberLimit, "pubkey number limit");

            depositAmount = uint256(1 ether);

            IUserDeposit(userDepositAddress).withdrawExcessBalanceForNodeDeposit(
                depositAmount * _validatorPubkeys.length
            );
        } else {
            require(lightNodeDepositEnabled, "light node deposits disabled");
            require(msg.value == _validatorPubkeys.length * lightNodeDepositAmount, "msg value not match");

            depositAmount = lightNodeDepositAmount;
            nodeDepositAmount = lightNodeDepositAmount;
        }

        node._pubkeyNumber++;

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

    function offBoard(bytes calldata _validatorPubkey) external override {
        setAndCheckNodePubkeyInOffBoard(_validatorPubkey);

        emit OffBoarded(msg.sender, _validatorPubkey);
    }

    function provideNodeDepositToken(bytes calldata _validatorPubkey) external payable override {
        PubkeyInfo memory pubkey = pubkeyInfoOf[_validatorPubkey];

        require(pubkey._status == PubkeyStatus.Offboard, "pubkey status unmatch");
        require(msg.value == pubkey._nodeDepositAmount, "msg value not match");

        _setNodePubkeyStatus(_validatorPubkey, PubkeyStatus.CanWithdraw);
    }

    function withdrawNodeDepositToken(bytes calldata _validatorPubkey) external override {
        PubkeyInfo memory pubkey = pubkeyInfoOf[_validatorPubkey];

        require(pubkey._status == PubkeyStatus.CanWithdraw, "pubkey status unmatch");
        require(msg.sender == pubkey._owner, "not pubkey owner");

        // set pubkey status
        _setNodePubkeyStatus(_validatorPubkey, PubkeyStatus.Withdrawed);

        (bool success, ) = (msg.sender).call{value: pubkey._nodeDepositAmount}("");
        require(success, "transferr failed");
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

        PubkeyInfo memory pubkey = pubkeyInfoOf[_validatorPubkey];

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
        require(pubkeyInfoOf[_pubkey]._status == PubkeyStatus.UnInitial, "pubkey already exists");

        // add pubkey
        pubkeyInfoOf[_pubkey] = PubkeyInfo({
            _nodeType: _nodeType,
            _status: PubkeyStatus.Initial,
            _owner: msg.sender,
            _nodeDepositAmount: _nodeDepositAmount
        });
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInStake(bytes calldata _pubkey) private {
        // check status
        require(pubkeyInfoOf[_pubkey]._status == PubkeyStatus.Match, "pubkey status unmatch");
        // check owner
        require(pubkeyInfoOf[_pubkey]._owner == msg.sender, "not pubkey owner");

        // set pubkey status
        _setNodePubkeyStatus(_pubkey, PubkeyStatus.Staking);
    }

    // Set and check a node's validator pubkey
    function setAndCheckNodePubkeyInOffBoard(bytes calldata _pubkey) private {
        PubkeyInfo memory pubkey = pubkeyInfoOf[_pubkey];

        require(pubkey._nodeType == NodeType.LightNode, "not light node");
        require(pubkey._status == PubkeyStatus.Match, "pubkey status unmatch");
        require(pubkey._owner == msg.sender, "not pubkey owner");

        // set pubkey status
        _setNodePubkeyStatus(_pubkey, PubkeyStatus.Offboard);
    }

    function _voteWithdrawCredentials(bytes calldata _pubkey, bool _match) private {
        bytes32 proposalId = keccak256(abi.encodePacked("voteWithdrawCredentials", _pubkey));

        // Finalize if Threshold has been reached
        if (INetworkProposal(networkProposalAddress).shouldExecute(proposalId, msg.sender)) {
            _setNodePubkeyStatus(_pubkey, _match ? PubkeyStatus.Match : PubkeyStatus.UnMatch);
        }
    }

    // Set a light node pubkey status
    function _setNodePubkeyStatus(bytes calldata _validatorPubkey, PubkeyStatus _status) private {
        pubkeyInfoOf[_validatorPubkey]._status = _status;

        emit SetPubkeyStatus(_validatorPubkey, _status);
    }
}
