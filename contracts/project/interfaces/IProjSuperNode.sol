pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjSuperNode {
    function depositEth() external payable;

    function getSuperNodeDepositEnabled() external view returns (bool);

    function ethDeposit(
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    ) external;

    function ethStake(
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    ) external;
}
