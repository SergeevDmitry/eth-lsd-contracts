pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface INetworkSettings {
    function getSubmitBalancesEnabled() external view returns (bool);

    function getWithdrawalCredentials() external view returns (bytes memory);

    function getSuperNodePubkeyLimit() external view returns (uint256);

    /***** light node start ******/
    function getLightNodeDepositEnabled() external view returns (bool);

    function getCurrentNodeDepositAmount() external view returns (uint256);
    /***** light node end ******/
}
