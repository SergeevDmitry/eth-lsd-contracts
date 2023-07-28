pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiFeePool {
    function withdrawEther(address _to, uint256 _amount) external;
}
