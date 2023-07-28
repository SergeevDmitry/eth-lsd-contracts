pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNodeManager {
    function setNodeTrusted(
        uint256 _pId,
        address _nodeAddress,
        bool _trusted
    ) external;
}
