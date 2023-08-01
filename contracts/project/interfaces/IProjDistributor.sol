pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjDistributor {
    function receiveEtherWithdrawal() external payable;

    function distributeWithdrawals(uint256 _value) external;

    function claimToAccount(uint256 _value, address _account) external;
}
