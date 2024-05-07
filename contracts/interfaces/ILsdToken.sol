// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "./IRateProvider.sol";
import "./Errors.sol";

interface ILsdToken is IRateProvider, Errors {
    function initMinter(address) external;
    function mint(address, uint256) external;
    function updateMinter(address _newMinter) external;
}
