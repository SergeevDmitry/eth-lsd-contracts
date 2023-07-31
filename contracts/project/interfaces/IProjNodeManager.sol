pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjNodeManager {
    function getTrustedNodeCount() external view returns (uint256);

    function getTrustedNodeAt(uint256 _index) external view returns (address);

    function getNodeTrusted(address _nodeAddress) external view returns (bool);

    function setNodeTrusted(address _nodeAddress, bool _trusted) external;

    function getSuperNodeCount() external view returns (uint256);

    function getSuperNodeAt(uint256 _index) external view returns (address);

    function getSuperNodeExists(
        address _nodeAddress
    ) external view returns (bool);

    function setNodeSuper(address _nodeAddress, bool _super) external;
}
