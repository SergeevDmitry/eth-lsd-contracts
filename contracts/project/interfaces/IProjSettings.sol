pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjSettings {
    function getNodeConsensusThreshold() external view returns (uint256);

    function getSubmitBalancesEnabled() external view returns (bool);

    function getWithdrawalCredentials() external view returns (bytes memory);

    function getSuperNodePubkeyLimit() external view returns (uint256);

    function getProjectFeePercent() external view returns (uint256);

    /***** light node start ******/
    function getLightNodeDepositEnabled() external view returns (bool);

    function getCurrentNodeDepositAmount() external view returns (uint256);

    /***** light node end ******/

    /***** distribute start ******/
    function getDistributeFeeUserPercent() external view returns (uint256);

    function getDistributeFeeNodePercent() external view returns (uint256);

    function getDistributeSuperNodeFeeUserPercent()
        external
        view
        returns (uint256);

    function getDistributeSuperNodeFeeNodePercent()
        external
        view
        returns (uint256);
    /***** distribute end ******/
}
