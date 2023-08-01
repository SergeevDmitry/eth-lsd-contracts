pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjLightNode {
    function depositEth() external payable;

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

    function provideEther(uint256 _value) external;

    function withdrawEther(address _user) external;
}
