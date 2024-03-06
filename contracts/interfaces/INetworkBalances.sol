// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "./Errors.sol";
import "./IUpgrade.sol";

interface INetworkBalances is Errors, IUpgrade {
    struct BalancesSnapshot {
        uint256 _block;
        uint256 _totalEth;
        uint256 _totalLsdToken;
    }

    event BalancesUpdated(uint256 block, uint256 totalEth, uint256 lsdTokenSupply, uint256 time);

    function init(address _networkProposalAddress) external;

    function getEthValue(uint256 _lsdTokenAmount) external view returns (uint256);

    function getLsdTokenValue(uint256 _ethAmount) external view returns (uint256);

    function getExchangeRate() external view returns (uint256);

    function submitBalances(uint256 _block, uint256 _totalEth, uint256 _totalLsdToken) external;
}
