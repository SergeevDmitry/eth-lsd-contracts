pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../common/StafiBase.sol";

abstract contract ProjContract is StafiBase {
    uint256 pId;

    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_stafiStorageAddress) {
        pId = _pId;
    }
}
