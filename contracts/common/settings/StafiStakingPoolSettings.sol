pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/settings/IStafiStakingPoolSettings.sol";
import "../types/DepositType.sol";

// Network staking pool settings
contract StafiStakingPoolSettings is StafiBase, IStafiStakingPoolSettings {
    // Libs
    using SafeMath for uint256;

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if (!getBoolS("settings.stakingpool.init")) {
            // Apply settings
            setLaunchTimeout(17280); // ~72 hours
            // Settings initialized
            setBoolS("settings.stakingpool.init", true);
        }
    }

    // Balance required to launch staking pool
    function getLaunchBalance() public pure override returns (uint256) {
        return 32 ether;
    }

    // Required node deposit amounts
    function getDepositNodeAmount(
        DepositType _depositType
    ) public pure override returns (uint256) {
        if (_depositType == DepositType.FOUR) {
            return getFourDepositNodeAmount();
        }
        if (_depositType == DepositType.EIGHT) {
            return getEightDepositNodeAmount();
        }
        if (_depositType == DepositType.TWELVE) {
            return getTwelveDepositNodeAmount();
        }
        if (_depositType == DepositType.SIXTEEN) {
            return getSixteenDepositNodeAmount();
        }
        if (_depositType == DepositType.Empty) {
            return 0 ether;
        }
        return 0;
    }

    function getFourDepositNodeAmount() public pure override returns (uint256) {
        return 4 ether;
    }

    function getEightDepositNodeAmount()
        public
        pure
        override
        returns (uint256)
    {
        return 8 ether;
    }

    function getTwelveDepositNodeAmount()
        public
        pure
        override
        returns (uint256)
    {
        return 12 ether;
    }

    function getSixteenDepositNodeAmount()
        public
        pure
        override
        returns (uint256)
    {
        return 16 ether;
    }

    // Required user deposit amounts
    function getDepositUserAmount(
        DepositType _depositType
    ) public pure override returns (uint256) {
        if (_depositType == DepositType.None) {
            return 0 ether;
        }
        return getLaunchBalance().sub(getDepositNodeAmount(_depositType));
    }

    // Timeout period in blocks for prelaunch staking pools to launch
    function getLaunchTimeout() public view override returns (uint256) {
        return getUintS("settings.stakingpool.launch.timeout");
    }

    function setLaunchTimeout(uint256 _value) public onlySuperUser {
        setUintS("settings.stakingpool.launch.timeout", _value);
    }

    // Submit staking pool refund currently enabled
    function getStakingPoolRefundedEnabled(
        address _stakingPoolAddress
    ) public view override returns (bool) {
        return
            getBool(
                keccak256(
                    abi.encodePacked(
                        "settings.stakingpool.refund.enabled",
                        _stakingPoolAddress
                    )
                )
            );
    }

    function setStakingPoolRefundedEnabled(
        address _stakingPoolAddress,
        bool _value
    ) public onlySuperUser {
        // Check current node status
        require(
            getBool(
                keccak256(
                    abi.encodePacked(
                        "settings.stakingpool.refund.enabled",
                        _stakingPoolAddress
                    )
                )
            ) != _value,
            "The node's refunded status is already set"
        );
        // Set status
        setBool(
            keccak256(
                abi.encodePacked(
                    "settings.stakingpool.refund.enabled",
                    _stakingPoolAddress
                )
            ),
            _value
        );
    }

    // Submit staking pool refund currently enabled
    function getStakingPoolTrustedRefundedEnabled(
        address _stakingPoolAddress
    ) public view override returns (bool) {
        return
            getBool(
                keccak256(
                    abi.encodePacked(
                        "settings.stakingpool.trusted.refund.enabled",
                        _stakingPoolAddress
                    )
                )
            );
    }

    function setStakingPoolTrustedRefundedEnabled(
        address _stakingPoolAddress,
        bool _value
    ) public onlySuperUser {
        // Check current node status
        require(
            getBool(
                keccak256(
                    abi.encodePacked(
                        "settings.stakingpool.trusted.refund.enabled",
                        _stakingPoolAddress
                    )
                )
            ) != _value,
            "The node's refunded status is already set"
        );
        // Set status
        setBool(
            keccak256(
                abi.encodePacked(
                    "settings.stakingpool.trusted.refund.enabled",
                    _stakingPoolAddress
                )
            ),
            _value
        );
    }
}
