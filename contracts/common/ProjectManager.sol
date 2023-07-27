pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./StafiBase.sol";
import "./types/Project.sol";

contract ProjectManager is StafiBase {
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {}

    function getProject(uint256 id) external returns (Project memory) {}

    function getProject(string memory name) external returns (Project memory) {}
}
