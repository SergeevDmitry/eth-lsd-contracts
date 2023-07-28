pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiNetworkBalances {
    function submitBalances(
        address _voter,
        uint256 _block,
        uint256 _total,
        uint256 _staking,
        uint256 _rethSupply
    ) external;
}
