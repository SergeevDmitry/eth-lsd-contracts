pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface ILsdToken {
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 time);

    function getEthValue(uint256 _lsdTokenAmount) external view returns (uint256);

    function getLsdTokenValue(uint256 _ethAmount) external view returns (uint256);

    function getExchangeRate() external view returns (uint256);

    function mint(address, uint256) external;
}
