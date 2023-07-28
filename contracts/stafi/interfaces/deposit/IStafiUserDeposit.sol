pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiUserDeposit {
    function deposit(address, uint256) external;
    function withdrawExcessBalance(uint256 _amount) external;
    function withdrawExcessBalanceForSuperNode(uint256 _amount) external;
    function withdrawExcessBalanceForLightNode(uint256 _amount) external;
    function withdrawExcessBalanceForWithdraw(uint256 _amount) external;
}
