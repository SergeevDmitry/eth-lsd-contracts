pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./IRateProvider.sol";
import "./Errors.sol";

interface ILsdToken is IRateProvider, Errors {
    function initMinter(address) external;

    function mint(address, uint256) external;
}
