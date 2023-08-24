pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface INodeDeposit {
    enum NodeType {
        Undefined,
        LightNode,
        SuperNode
    }

    enum PubkeyStatus {
        UnInitial,
        Initial,
        Match,
        Staking,
        UnMatch,
        Offboard,
        CanWithdraw,
        Withdrawed
    }

    struct Pubkey {
        NodeType _nodeType;
        PubkeyStatus _status;
        address _owner;
        uint256 _nodeDepositAmount;
    }
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Deposited(address node, bytes pubkey, bytes validatorSignature, uint256 amount);
    event Staked(address node, bytes pubkey);
    event OffBoarded(address node, bytes pubkey);
    event SetPubkeyStatus(bytes pubkey, PubkeyStatus status);

    function depositEth() external payable;

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

    function offBoard(bytes calldata _validatorPubkey) external;

    function provideNodeDepositToken(bytes calldata _validatorPubkey) external payable;

    function withdrawNodeDepositToken(bytes calldata _validatorPubkey) external;

    function voteWithdrawCredentials(bytes[] calldata _pubkey, bool[] calldata _match) external;
}
