pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IUserDeposit {
    function deposit() external payable;

    function withdrawExcessBalanceForNodeDeposit(uint256 _amount) external;

    function withdrawExcessBalanceForUserWithdraw(uint256 _amount) external;

    function recycleDistributorDeposit() external payable;

    function recycleWithdrawDeposit() external payable;

    function getBalance() external view returns (uint256);
}
