pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./IRateProvider.sol";

interface ILsdToken is IRateProvider {
    function mint(address, uint256) external;
}
