pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjWithdraw {
    function depositEth() external payable;

    function doWithdraw(address _user, uint256 _amount) external;

    function recycleUserDeposit(uint256 _value) external;

    function doDistributeWithdrawals(uint256 _value) external;

    function withdrawCommission(uint256 _value) external;
}
