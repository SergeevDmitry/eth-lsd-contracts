pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../stafi/StafiBase.sol";
import "../stafi/interfaces/network/IStafiNetworkBalances.sol";
import "../stafi/interfaces/node/IStafiNodeManager.sol";
import "./interfaces/IProjBalances.sol";
import "./interfaces/IProjSettings.sol";

// Network balances
contract ProjBalances is StafiBase, IProjBalances {
    // Libs
    using SafeMath for uint256;

    // Events
    event BalancesSubmitted(
        address indexed from,
        uint256 block,
        uint256 totalEth,
        uint256 stakingEth,
        uint256 rethSupply,
        uint256 time
    );
    event BalancesUpdated(
        uint256 block,
        uint256 totalEth,
        uint256 stakingEth,
        uint256 rethSupply,
        uint256 time
    );

    // Construct
    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
    }

    // The block number which balances are current for
    function getBalancesBlock() public view override returns (uint256) {
        return
            getUint(
                keccak256(abi.encode("network.balances.updated.block", pId))
            );
    }

    function setBalancesBlock(uint256 _value) private {
        setUint(
            keccak256(abi.encode("network.balances.updated.block", pId)),
            _value
        );
    }

    // The current network total ETH balance
    function getTotalETHBalance() public view override returns (uint256) {
        return getUint(keccak256(abi.encode("network.balance.total", pId)));
    }

    function setTotalETHBalance(uint256 _value) private {
        setUint(keccak256(abi.encode("network.balance.total", pId)), _value);
    }

    // The current network staking ETH balance
    function getStakingETHBalance() public view override returns (uint256) {
        return getUint(keccak256(abi.encode("network.balance.staking", pId)));
    }

    function setStakingETHBalance(uint256 _value) private {
        setUint(keccak256(abi.encode("network.balance.staking", pId)), _value);
    }

    // The current network total rETH supply
    function getTotalRETHSupply() public view override returns (uint256) {
        return
            getUint(keccak256(abi.encode("network.balance.reth.supply", pId)));
    }

    function setTotalRETHSupply(uint256 _value) private {
        setUint(
            keccak256(abi.encode("network.balance.reth.supply", pId)),
            _value
        );
    }

    // Get the current network ETH staking rate as a fraction of 1 ETH
    // Represents what % of the network's balance is actively earning rewards
    function getETHStakingRate() public view override returns (uint256) {
        uint256 calcBase = 1 ether;
        uint256 totalEthBalance = getTotalETHBalance();
        uint256 stakingEthBalance = getStakingETHBalance();
        if (totalEthBalance == 0) {
            return calcBase;
        }
        return calcBase.mul(stakingEthBalance).div(totalEthBalance);
    }

    // Submit network balances for a block
    // Only accepts calls from trusted (oracle) nodes
    function submitBalances(
        uint256 _block,
        uint256 _totalEth,
        uint256 _stakingEth,
        uint256 _rethSupply
    )
        external
        onlyLatestContract(pId, "projBalances", address(this))
        onlyTrustedNode(pId, msg.sender)
    {
        IStafiNetworkBalances stafiNetworkBalances = IStafiNetworkBalances(
            getContractAddress(1, "stafiNetworkBalances")
        );
        address _voter = msg.sender;
        bool agreed = stafiNetworkBalances.submitBalances(
            _voter,
            _block,
            _totalEth,
            _stakingEth,
            _rethSupply
        );
        emit BalancesSubmitted(
            _voter,
            _block,
            _totalEth,
            _stakingEth,
            _rethSupply,
            block.timestamp
        );
        if (agreed) updateBalances(_block, _totalEth, _stakingEth, _rethSupply);
    }

    // Update network balances
    function updateBalances(
        uint256 _block,
        uint256 _totalEth,
        uint256 _stakingEth,
        uint256 _rethSupply
    ) private {
        // Update balances
        setBalancesBlock(_block);
        setTotalETHBalance(_totalEth);
        setStakingETHBalance(_stakingEth);
        setTotalRETHSupply(_rethSupply);
        // Emit balances updated event
        emit BalancesUpdated(
            _block,
            _totalEth,
            _stakingEth,
            _rethSupply,
            block.timestamp
        );
    }
}
