pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "../stafi/interfaces/node/IStafiNodeManager.sol";
import "../stafi/interfaces/storage/IAddressSetStorage.sol";
import "./interfaces/IProjNodeManager.sol";

// Node registration and management
contract ProjNodeManager is StafiBase, IProjNodeManager {
    // Events
    event NodeTrustedSet(address indexed node, bool trusted, uint256 time);
    event NodeSuperSet(address indexed node, bool trusted, uint256 time);

    // Construct
    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
    }

    // Get the number of trusted nodes in the network
    function getTrustedNodeCount() public view override returns (uint256) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(
            getContractAddress(1, "addressSetStorage")
        );
        return
            addressSetStorage.getCount(
                keccak256(abi.encodePacked("nodes.trusted.index", pId))
            );
    }

    // Get a trusted node address by index
    function getTrustedNodeAt(
        uint256 _index
    ) public view override returns (address) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(
            getContractAddress(1, "addressSetStorage")
        );
        return
            addressSetStorage.getItem(
                keccak256(abi.encodePacked("nodes.trusted.index", pId)),
                _index
            );
    }

    // Check whether a node is trusted
    function getNodeTrusted(
        address _nodeAddress
    ) public view override returns (bool) {
        return
            getBool(
                keccak256(abi.encodePacked("node.trusted", pId, _nodeAddress))
            );
    }

    // Set a node's trusted status
    // Only accepts calls from super users
    function setNodeTrusted(
        address _nodeAddress,
        bool _trusted
    )
        external
        override
        onlyLatestContract(pId, "projNodeManger", address(this))
        onlySuperUser(pId)
    {
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(
            getContractAddress(1, "stafiNodeManager")
        );
        stafiNodeManager.setNodeTrusted(_nodeAddress, _trusted);
        emit NodeTrustedSet(_nodeAddress, _trusted, block.timestamp);
    }

    // Get the number of super nodes in the network
    function getSuperNodeCount() public view override returns (uint256) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(
            getContractAddress(1, "addressSetStorage")
        );
        return
            addressSetStorage.getCount(
                keccak256(abi.encodePacked("nodes.super.index", pId))
            );
    }

    // Get a trusted node address by index
    function getSuperNodeAt(
        uint256 _index
    ) public view override returns (address) {
        IAddressSetStorage addressSetStorage = IAddressSetStorage(
            getContractAddress(1, "addressSetStorage")
        );
        return
            addressSetStorage.getItem(
                keccak256(abi.encodePacked("nodes.super.index", pId)),
                _index
            );
    }

    // Check whether a node is trusted
    function getSuperNodeExists(
        address _nodeAddress
    ) public view override returns (bool) {
        return
            getBool(
                keccak256(abi.encodePacked("node.super", pId, _nodeAddress))
            );
    }

    // Set a node's super status
    // Only accepts calls from super users
    function setNodeSuper(
        address _nodeAddress,
        bool _super
    )
        external
        override
        onlyLatestContract(pId, "projNodeManger", address(this))
        onlySuperUser(pId)
    {
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(
            getContractAddress(1, "stafiNodeManager")
        );
        stafiNodeManager.setNodeSuper(_nodeAddress, _super);
        emit NodeSuperSet(_nodeAddress, _super, block.timestamp);
    }
}
