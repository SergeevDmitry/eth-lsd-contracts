pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IRETHToken {
    function userMint(uint256 _pId, address _to, uint256 _ethAmount) external;
}
