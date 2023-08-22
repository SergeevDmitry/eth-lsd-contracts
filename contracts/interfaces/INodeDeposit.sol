pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface INodeDeposit {
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
