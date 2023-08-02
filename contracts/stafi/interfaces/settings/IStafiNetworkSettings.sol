pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNetworkSettings {
    function getStafiFeeRatio(uint256 _pId) external view returns (uint256);

    function getDefaultStafiFeeRatio() external returns (uint256);

    function initializeStafiFeeRatio(uint256 _pId, uint256 _value) external;
}
