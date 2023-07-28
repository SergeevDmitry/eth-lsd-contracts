pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "./interfaces/IProjSettings.sol";

contract ProjSettings is StafiBase, IProjSettings {
    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
        if (!getBool(keccak256(abi.encode("settings.network.init", _pId)))) {
            // Apply settings
            setNodeConsensusThreshold(0.5 ether); // 50%
            setSubmitBalancesEnabled(true);
            setSuperNodePubkeyLimit(50);
            // Settings initialized
            setBool(keccak256(abi.encode("settings.network.init", _pId)), true);
        }
    }

    // The threshold of trusted nodes that must reach consensus on oracle data to commit it
    function getNodeConsensusThreshold()
        public
        view
        override
        returns (uint256)
    {
        return
            getUint(
                keccak256(
                    abi.encode("settings.network.consensus.threshold", pId)
                )
            );
    }

    function setNodeConsensusThreshold(
        uint256 _value
    ) public onlySuperUser(pId) {
        setUint(
            keccak256(abi.encode("settings.network.consensus.threshold", pId)),
            _value
        );
    }

    // Submit balances currently enabled (trusted nodes only)
    function getSubmitBalancesEnabled() public view override returns (bool) {
        return
            getBool(
                keccak256(
                    abi.encode("settings.network.submit.balances.enabled", pId)
                )
            );
    }

    function setSubmitBalancesEnabled(bool _value) public onlySuperUser(pId) {
        setBool(
            keccak256(
                abi.encode("settings.network.submit.balances.enabled", pId)
            ),
            _value
        );
    }

    // Get the validator withdrawal credentials
    function getWithdrawalCredentials()
        public
        view
        override
        returns (bytes memory)
    {
        return
            getBytes(
                keccak256(
                    abi.encode("settings.network.withdrawal.credentials", pId)
                )
            );
    }

    // Set the validator withdrawal credentials
    function setWithdrawalCredentials(
        bytes memory _value
    ) public onlySuperUser(pId) {
        setBytes(
            keccak256(
                abi.encode("settings.network.withdrawal.credentials", pId)
            ),
            _value
        );
    }

    // Get super node pubkey limit
    function getSuperNodePubkeyLimit() public view override returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encode("settings.network.superNode.pubkeyLimit", pId)
                )
            );
    }

    // Set super node pubkey limit
    function setSuperNodePubkeyLimit(uint256 _value) public onlySuperUser(pId) {
        setUint(
            keccak256(
                abi.encode("settings.network.superNode.pubkeyLimit", pId)
            ),
            _value
        );
    }
}
