pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "./IDepositEth.sol";
import "./Errors.sol";
import "./IUpgrade.sol";

interface INodeDeposit is IDepositEth, Errors, IUpgrade {
    enum NodeType {
        Undefined,
        SoloNode,
        TrustNode
    }

    enum PubkeyStatus {
        UnInitial,
        Deposited,
        Match,
        Staked,
        UnMatch
    }

    struct PubkeyInfo {
        PubkeyStatus _status;
        address _owner;
        uint256 _nodeDepositAmount;
        uint256 _depositBlock;
    }

    struct NodeInfo {
        NodeType _nodeType;
        bool _removed;
        uint256 _pubkeyNumber;
    }

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Deposited(address node, NodeType nodeType, bytes pubkey, bytes validatorSignature, uint256 amount);
    event Staked(address node, bytes pubkey);
    event SetPubkeyStatus(bytes pubkey, PubkeyStatus status);

    function deposit(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external payable;

    function stake(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external;

    function init(
        address _userDepositAddress,
        address _ethDepositAddress,
        address _networkProposalAddress,
        bytes calldata _withdrawCredentials
    ) external;

    function voteWithdrawCredentials(bytes calldata _pubkey, bool _match) external;
}
