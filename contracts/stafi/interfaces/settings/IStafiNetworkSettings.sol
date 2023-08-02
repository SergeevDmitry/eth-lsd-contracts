pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNetworkSettings {
    function getStafiFeePercent() external view returns (uint256);
}
