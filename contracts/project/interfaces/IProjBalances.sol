pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjBalances {
    function getBalancesBlock() external view returns (uint256);

    function getTotalETHBalance() external view returns (uint256);

    function getStakingETHBalance() external view returns (uint256);

    function getTotalRETHSupply() external view returns (uint256);

    function getETHStakingRate() external view returns (uint256);
}
