pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjDistributor {
    function receiveEtherWithdrawal() external payable;

    function distributeWithdrawals() external payable;

    function claimToAccount(uint256 _value, address _account) external;
}
