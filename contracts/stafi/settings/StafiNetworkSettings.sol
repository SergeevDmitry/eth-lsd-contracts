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
        if (!getBool(keccak256(abi.encode("settings.network.init", 1)))) {
            // Apply settings
            setPlatformFeePercent(50); // 10%
            // Settings initialized
            setBool(keccak256(abi.encode("settings.network.init", 1)), true);
        }
    }

    // The platform commission rate as a fraction of 1 ether
    function getPlatformFeePercent() public view override returns (uint256) {
        return
            getUint(keccak256(abi.encode("settings.network.platform.fee", 1)));
    }

    // TODO: platform super user + project super user
    function setPlatformFeePercent(uint256 _value) public onlySuperUser(1) {
        require(_value <= 1000, "Invalid value");
        setUint(
            keccak256(abi.encode("settings.network.platform.fee", 1)),
            _value
        );
    }
}
