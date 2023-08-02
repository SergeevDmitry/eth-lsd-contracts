pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";

// Network settings
contract StafiNetworkSettings is StafiBase, IStafiNetworkSettings {
    // Construct
    constructor(
        address _stafiStorageAddress
    ) StafiBase(1, _stafiStorageAddress) {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if (!getBool(keccak256(abi.encode("settings.init", 1)))) {
            // Settings initialized
            setBool(keccak256(abi.encode("settings.init", 1)), true);
        }
    }

    // The platform commission rate as a fraction of 1 ether
    function getStafiFeePercent(
        uint256 _pId
    ) public view override returns (uint256) {
        return getUint(keccak256(abi.encode("settings.platform.fee", _pId)));
    }

    // TODO: stafi proposal and project approve
    function updateStafiFeePercent(
        uint256 _pId,
        uint256 _value
    ) public onlySuperUser(1) {
        require(_value <= 1000, "Invalid value");
        setUint(keccak256(abi.encode("settings.platform.fee", _pId)), _value);
    }

    function initializeStafiFeePercent(
        uint256 _pId,
        uint256 _value
    ) public onlyLatestContract(1, "stafiContractManager", msg.sender) {
        require(_value <= 1000, "Invalid value");
        setUint(keccak256(abi.encode("settings.platform.fee", _pId)), _value);
    }
}
