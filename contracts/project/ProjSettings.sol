pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "./interfaces/IProjSettings.sol";

contract ProjSettings is StafiBase, IProjSettings {
    constructor(uint256 _pId, address _stafiStorageAddress) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
        if (!getBool(keccak256(abi.encode("settings.init", _pId)))) {
            // Apply settings
            setNodeConsensusThreshold(0.5 ether); // 50%
            setSubmitBalancesEnabled(true);
            setSuperNodePubkeyLimit(50);
            setCurrentNodeDepositAmount(4 ether);
            setDistributeFeeUserPercent(900);
            setDistributeFeeNodePercent(100);
            setDistributeSuperNodeFeeUserPercent(950);
            setDistributeSuperNodeFeeNodePercent(50);
            // Settings initialized
            setBool(keccak256(abi.encode("settings.init", _pId)), true);
        }
    }

    // The threshold of trusted nodes that must reach consensus on oracle data to commit it
    function getNodeConsensusThreshold() public view override returns (uint256) {
        return getUint(keccak256(abi.encode("settings.consensus.threshold", pId)));
    }

    function setNodeConsensusThreshold(uint256 _value) public onlySuperUser(pId) {
        setUint(keccak256(abi.encode("settings.consensus.threshold", pId)), _value);
    }

    // Submit balances currently enabled (trusted nodes only)
    function getSubmitBalancesEnabled() public view override returns (bool) {
        return getBool(keccak256(abi.encode("settings.submit.balances.enabled", pId)));
    }

    function setSubmitBalancesEnabled(bool _value) public onlySuperUser(pId) {
        setBool(keccak256(abi.encode("settings.submit.balances.enabled", pId)), _value);
    }

    // Get the validator withdrawal credentials
    function getWithdrawalCredentials() public view override returns (bytes memory) {
        return getBytes(keccak256(abi.encode("settings.withdrawal.credentials", pId)));
    }

    // Set the validator withdrawal credentials
    function setWithdrawalCredentials(bytes memory _value) public onlySuperUser(pId) {
        setBytes(keccak256(abi.encode("settings.withdrawal.credentials", pId)), _value);
    }

    // Get super node pubkey limit
    function getSuperNodePubkeyLimit() public view override returns (uint256) {
        return getUint(keccak256(abi.encode("settings.superNode.pubkeyLimit", pId)));
    }

    // Set super node pubkey limit
    function setSuperNodePubkeyLimit(uint256 _value) public onlySuperUser(pId) {
        setUint(keccak256(abi.encode("settings.superNode.pubkeyLimit", pId)), _value);
    }

    function getProjectFeePercent() external view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.fee.percent", pId)));
    }

    function setProjectFeePercent(uint256 _value) external onlySuperUser(pId) {
        require(_value >= 0 && _value <= 1000, "Invalid project fee percent");
        setUint(keccak256(abi.encode("settings.fee.percent", pId)), _value);
    }

    /***** light node start *****/

    function getLightNodeDepositEnabled() external view returns (bool) {
        return getBool(keccak256(abi.encode("settings.lightNode.deposit.enabled", pId)));
    }

    function setLightNodeDepositEnabled(bool _value) public onlySuperUser(pId) {
        setBool(keccak256(abi.encode("settings.lightNode.deposit.enabled", pId)), _value);
    }

    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.node.deposit.amount", pId)));
    }

    function setCurrentNodeDepositAmount(uint256 _value) public onlySuperUser(pId) {
        setUint(keccak256(abi.encode("settings.node.deposit.amount", pId)), _value);
    }

    /***** light node end *****/

    /***** distribute start *****/

    function getDistributeFeeUserPercent() external view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.distribute.fee.user", pId)));
    }

    function setDistributeFeeUserPercent(uint256 _value) public onlySuperUser(pId) {
        require(_value <= 1000 && _value > 0, "Invalid percent");
        setUint(keccak256(abi.encode("settings.distribute.fee.user", pId)), _value);
    }

    function getDistributeFeeNodePercent() external view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.distribute.fee.node", pId)));
    }

    function setDistributeFeeNodePercent(uint256 _value) public onlySuperUser(pId) {
        require(_value <= 1000 && _value > 0, "Invalid percent");
        setUint(keccak256(abi.encode("settings.distribute.fee.node", pId)), _value);
    }

    function getDistributeSuperNodeFeeUserPercent() public view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.distribute.supernodefee.user", pId)));
    }

    function setDistributeSuperNodeFeeUserPercent(uint256 _value) public onlySuperUser(pId) {
        require(_value <= 1000 && _value > 0, "Invalid percent");
        setUint(keccak256(abi.encode("settings.distribute.supernodefee.user", pId)), _value);
    }

    function getDistributeSuperNodeFeeNodePercent() public view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.distribute.supernodefee.node", pId)));
    }

    function setDistributeSuperNodeFeeNodePercent(uint256 _value) public onlySuperUser(pId) {
        require(_value <= 1000 && _value > 0, "Invalid percent");
        setUint(keccak256(abi.encode("settings.distribute.supernodefee.node", pId)), _value);
    }

    /***** distribute end *****/
}
