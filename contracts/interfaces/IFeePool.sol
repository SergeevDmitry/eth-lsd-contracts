pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IFeePool {
    event EtherWithdrawn(uint256 amount, uint256 time);

    function init(address _address) external;

    function withdrawEther(uint256 _amount) external;
}
