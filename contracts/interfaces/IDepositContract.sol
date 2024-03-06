// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

interface IDepositContract {
    function deposit(
        bytes calldata _pubkey,
        bytes calldata _withdrawalCredentials,
        bytes calldata _signature,
        bytes32 _depositDataRoot
    ) external payable;
}
