pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INetworkSettings.sol";

contract NetworkSettings is INetworkSettings {
    bool public depositEnabled;
    uint256 public minDeposit;
    bool public initialized;
    bool public submitBalancesEnabled;
    bytes public withdrawalCredentials;
    uint256 public superNodePubkeyLimit;

    bool public lightNodeDepositEnabled;
    uint256 public currentNodeDepositAmount;

    address public admin;
    address public rTokenAddress;
    address public superNodeAddress;
    address public lightNodeAddress;
    address public withdrawAddress;
    address public distributorAddress;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Invalid admin");
        _;
    }

    function initialize() public {
        require(!initialized, "already initialized");
        // Apply settings
        setSubmitBalancesEnabled(true);
        setSuperNodePubkeyLimit(50);
        setCurrentNodeDepositAmount(4 ether);
        // Settings initialized
        initialized = true;
    }

    // Submit balances currently enabled (trusted nodes only)
    function getSubmitBalancesEnabled() public view override returns (bool) {
        return submitBalancesEnabled;
    }

    function setSubmitBalancesEnabled(bool _value) public onlyAdmin {
        submitBalancesEnabled = _value;
    }

    // Get the validator withdrawal credentials
    function getWithdrawalCredentials() public view override returns (bytes memory) {
        return withdrawalCredentials;
    }

    // Set the validator withdrawal credentials
    function setWithdrawalCredentials(bytes memory _value) public onlyAdmin {
        withdrawalCredentials = _value;
    }

    // Get super node pubkey limit
    function getSuperNodePubkeyLimit() public view override returns (uint256) {
        return superNodePubkeyLimit;
    }

    // Set super node pubkey limit
    function setSuperNodePubkeyLimit(uint256 _value) public onlyAdmin {
        superNodePubkeyLimit = _value;
    }

    /***** light node start *****/

    function getLightNodeDepositEnabled() external view returns (bool) {
        return lightNodeDepositEnabled;
    }

    function setLightNodeDepositEnabled(bool _value) public onlyAdmin {
        lightNodeDepositEnabled = _value;
    }

    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return currentNodeDepositAmount;
    }

    function setCurrentNodeDepositAmount(uint256 _value) public onlyAdmin {
        currentNodeDepositAmount = _value;
    }

    /***** light node end *****/
}
