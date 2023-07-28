pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "../stafi/interfaces/node/IStafiNodeManager.sol";
import "./interfaces/IProjNodeManager.sol";


// Node registration and management
contract StafiNodeManager is StafiBase, IProjNodeManager {
    // Events
    event NodeTrustedSet(address indexed node, bool trusted, uint256 time);

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
            getContractAddress("addressSetStorage")
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
            getContractAddress("addressSetStorage")
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
        onlySuperUser(_pId)
    {
        IStafiNodeManager stafiNodeManager = IStafiNodeManager(getContractAddress(1, "stafiNodeManager"));
        stafiNodeManager.setNodeTrusted();
        emit NodeTrustedSet(_nodeAddress, _trusted, block.timestamp);
    }
}
