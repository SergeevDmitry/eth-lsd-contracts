pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjFeePool {
    function recycleUserDeposit(uint256 _value) external;

    function depositEther(uint256) external;

    function withdrawCommission(uint256 _value) external;
}
