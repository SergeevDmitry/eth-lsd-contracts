pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INetworkBalances.sol";
import "./interfaces/INodeManager.sol";
import "./interfaces/INetworkSettings.sol";
import "./NetworkProposal.sol";

// Network balances
contract NetworkBalances is NetworkProposal, INetworkBalances {
    bool public initialized;
    address public networkSettingsAddress;

    uint256 public balanceBlock;
    uint256 public totalEthBalance;
    uint256 public totalRTokenSupply;
    uint256 public stakingEthBalance;

    // Events
    event BalancesSubmitted(
        address indexed from,
        uint256 block,
        uint256 totalEth,
        uint256 stakingEth,
        uint256 rethSupply,
        uint256 time
    );
    event BalancesUpdated(uint256 block, uint256 totalEth, uint256 stakingEth, uint256 rethSupply, uint256 time);

    // The block number which balances are current for
    function getBalancesBlock() public view override returns (uint256) {
        return balanceBlock;
    }

    // The current network total ETH balance
    function getTotalETHBalance() public view override returns (uint256) {
        return totalEthBalance;
    }

    // The current network staking ETH balance
    function getStakingETHBalance() public view override returns (uint256) {
        return stakingEthBalance;
    }

    // The current network total rETH supply
    function getTotalRETHSupply() public view override returns (uint256) {
        return totalRTokenSupply;
    }

    // Get the current network ETH staking rate as a fraction of 1 ETH
    // Represents what % of the network's balance is actively earning rewards
    function getETHStakingRate() public view override returns (uint256) {
        uint256 calcBase = 1 ether;
        if (totalEthBalance == 0) {
            return calcBase;
        }
        return (calcBase * stakingEthBalance) / totalEthBalance;
    }

    // Submit network balances for a block
    // Only accepts calls from trusted (oracle) nodes
    function submitBalances(
        uint256 _block,
        uint256 _totalEth,
        uint256 _stakingEth,
        uint256 _rethSupply
    ) external override onlyVoter {
        // Check settings
        INetworkSettings stafiNetworkSettings = INetworkSettings(networkSettingsAddress);
        require(stafiNetworkSettings.getSubmitBalancesEnabled(), "Submitting balances is currently disabled");
        // Check block
        require(_block > balanceBlock, "Network balances for an equal or higher block are set");
        // Check balances
        require(_stakingEth <= _totalEth, "Invalid network balances");
        // Get submission keys
        bytes32 proposalId = keccak256(
            abi.encodePacked("network.balances.submitted.node", msg.sender, _block, _totalEth, _stakingEth, _rethSupply)
        );

        Proposal memory proposal = _checkProposal(proposalId);

        // Emit balances submitted event
        emit BalancesSubmitted(msg.sender, _block, _totalEth, _stakingEth, _rethSupply, block.timestamp);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            updateBalances(_block, _totalEth, _stakingEth, _rethSupply);

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId);
        }
        proposals[proposalId] = proposal;
    }

    // Update network balances
    function updateBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _rethSupply) private {
        // Update balances
        balanceBlock = _block;
        totalEthBalance = _totalEth;
        stakingEthBalance = _stakingEth;
        totalRTokenSupply = _rethSupply;

        // Emit balances updated event
        emit BalancesUpdated(_block, _totalEth, _stakingEth, _rethSupply, block.timestamp);
    }
}
