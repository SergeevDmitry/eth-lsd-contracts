pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNodeManager {
    function setNodeTrusted(address _nodeAddress, bool _trusted) external;

    function setNodeSuper(address _nodeAddress, bool _super) external;
}
