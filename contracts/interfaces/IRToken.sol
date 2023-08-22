pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IRToken {
    function getEthValue(uint256 _rethAmount) external view returns (uint256);

    function getRethValue(uint256 _ethAmount) external view returns (uint256);

    function getExchangeRate() external view returns (uint256);

    function mint(address, uint256) external;
}
