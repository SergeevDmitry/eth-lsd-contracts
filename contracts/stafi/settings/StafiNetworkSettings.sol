pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../StafiBase.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";

// Network settings
contract StafiNetworkSettings is StafiBase, IStafiNetworkSettings {
    event StafiFeeRatioProposal(uint256 pId, uint256 value);
    event StafiFeeRatioUpdate(uint256 pId, uint256 value);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(1, _stafiStorageAddress) {
        // Set version
        version = 1;
        // Initialize settings on deployment
        if (!getBool(keccak256(abi.encode("settings.init", 1)))) {
            // Apply settings
            setDefaulStafiFeeRatio(300); // 30% 300/1000
            // Settings initialized
            setBool(keccak256(abi.encode("settings.init", 1)), true);
        }
    }

    function getDefaultStafiFeeRatio() public view returns (uint256) {
        return getUintS("settings.protocol.fee.default");
    }

    function setDefaulStafiFeeRatio(uint256 _value) public onlySuperUser(1) {
        return setUintS("settings.protocol.fee.default", _value);
    }

    // The platform commission rate as a fraction of 1 ether
    function getStafiFeeRatio(uint256 _pId) public view override returns (uint256) {
        return getUint(keccak256(abi.encode("settings.protocol.fee", _pId)));
    }

    // stafi proposal and project approve
    function proposalStafiFeeRatio(uint256 _pId, uint256 _value) external onlySuperUser(1) {
        require(_value <= 1000 && _value > 0, "Invalid fee ratio");
        setUint(keccak256(abi.encode("settings.protocol.fee.proposal", _pId)), _value);
        emit StafiFeeRatioProposal(_pId, _value);
    }

    function getStafiFeeRatioProposal(uint256 _pId) public view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.protocol.fee.proposal", _pId)));
    }

    function agreeStafiFeeRatio(uint256 _value) external {
        uint256 _pId = getProjectId(msg.sender);
        require(_pId > 1 && getContractAddress(_pId, "projSettings") == msg.sender, "Invalid caller");
        uint256 _proposalValue = getStafiFeeRatioProposal(_pId);
        require(_proposalValue > 0, "Invalid proposal fee ratio");
        require(_proposalValue == _value, "Invalid agreed fee ratio");
        updateStafiFeeRatio(_pId, _value);
    }

    function updateStafiFeeRatio(uint256 _pId, uint256 _value) private {
        setUint(keccak256(abi.encode("settings.protocol.fee", _pId)), _value);
        deleteUint(keccak256(abi.encode("settings.protocol.fee.proposal", _pId)));
        emit StafiFeeRatioUpdate(_pId, _value);
    }

    function initializeStafiFeeRatio(
        uint256 _pId,
        uint256 _value
    ) external onlyLatestContract(1, "stafiContractManager", msg.sender) {
        require(_value <= 1000 && _value > 0, "Invalid value");
        setUint(keccak256(abi.encode("settings.protocol.fee", _pId)), _value);
    }
}
