pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INetworkBalances.sol";
import "./interfaces/INetworkProposal.sol";
import "./interfaces/IProposalType.sol";

// Network balances
contract NetworkBalances is INetworkBalances, IProposalType {
    bool public initialized;
    bool public submitBalancesEnabled;

    uint256 public balanceBlock;
    uint256 public totalEthBalance;
    uint256 public totalLsdTokenSupply;
    uint256 public stakingEthBalance;

    address public networkProposalAddress;

    modifier onlyVoter() {
        require(INetworkProposal(networkProposalAddress).isVoter(msg.sender), "not voter");
        _;
    }

    function init(address _networkProposalAddress) external override {
        require(!initialized, "already initialized");

        initialized = true;
        submitBalancesEnabled = true;
        networkProposalAddress = _networkProposalAddress;
    }

    // ------------ getter ------------

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

    // The current network total lsdToken supply
    function getTotalLsdTokenSupply() public view override returns (uint256) {
        return totalLsdTokenSupply;
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

    // ------------ voter ------------

    // Submit network balances for a block
    // Only accepts calls from trusted (oracle) nodes
    function submitBalances(
        uint256 _block,
        uint256 _totalEth,
        uint256 _stakingEth,
        uint256 _lsdTokenSupply
    ) external override onlyVoter {
        require(submitBalancesEnabled, "submitting balances is disabled");
        require(_block > balanceBlock, "network balances for an equal or higher block are set");
        require(_stakingEth <= _totalEth, "invalid network balances");

        bytes32 proposalId = keccak256(
            abi.encodePacked("submitBalances", _block, _totalEth, _stakingEth, _lsdTokenSupply)
        );

        INetworkProposal networkProposal = INetworkProposal(networkProposalAddress);
        (Proposal memory proposal, uint8 threshold) = networkProposal.checkProposal(proposalId);

        // Emit balances submitted event
        emit BalancesSubmitted(msg.sender, _block, _totalEth, _stakingEth, _lsdTokenSupply, block.timestamp);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            updateBalances(_block, _totalEth, _stakingEth, _lsdTokenSupply);

            proposal._status = ProposalStatus.Executed;
            emit ProposalExecuted(proposalId);
        }

        networkProposal.saveProposal(proposalId, proposal);
    }

    // ------------ helper ------------

    // Update network balances
    function updateBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _lsdTokenSupply) private {
        // Update balances
        balanceBlock = _block;
        totalEthBalance = _totalEth;
        stakingEthBalance = _stakingEth;
        totalLsdTokenSupply = _lsdTokenSupply;

        // Emit balances updated event
        emit BalancesUpdated(_block, _totalEth, _stakingEth, _lsdTokenSupply, block.timestamp);
    }
}
