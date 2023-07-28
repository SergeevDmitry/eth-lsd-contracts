pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjRToken {
    function mint(address, uint256) external;
    function depositRewards() external payable;
    function depositExcess() external payable;
}
