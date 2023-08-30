pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface INetworkBalances {
    // Events
    event BalancesSubmitted(
        address indexed from,
        uint256 block,
        uint256 totalEth,
        uint256 stakingEth,
        uint256 lsdTokenSupply,
        uint256 time
    );
    event BalancesUpdated(uint256 block, uint256 totalEth, uint256 stakingEth, uint256 lsdTokenSupply, uint256 time);

    function init(address _networkProposalAddress) external;

    function getEthValue(uint256 _lsdTokenAmount) external view returns (uint256);

    function getLsdTokenValue(uint256 _ethAmount) external view returns (uint256);

    function getExchangeRate() external view returns (uint256);

    function balancesBlock() external view returns (uint256);

    function totalEthBalance() external view returns (uint256);

    function stakingEthBalance() external view returns (uint256);

    function totalLsdTokenSupply() external view returns (uint256);

    function getETHStakingRate() external view returns (uint256);

    function submitBalances(uint256 _block, uint256 _total, uint256 _staking, uint256 _lsdTokenSupply) external;
}
