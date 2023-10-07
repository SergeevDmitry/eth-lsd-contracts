pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IDepositContract {
    function deposit(
        bytes calldata _pubkey,
        bytes calldata _withdrawalCredentials,
        bytes calldata _signature,
        bytes32 _depositDataRoot
    ) external payable;
}
