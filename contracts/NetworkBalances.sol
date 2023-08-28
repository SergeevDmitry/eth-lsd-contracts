pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INetworkBalances.sol";
import "./interfaces/INetworkProposal.sol";

// Network balances
contract NetworkBalances is INetworkBalances {
    bool public initialized;
    uint8 public version;
    bool public submitBalancesEnabled;

    uint256 public balancesBlock;
    uint256 public totalEthBalance;
    uint256 public totalLsdTokenSupply;
    uint256 public stakingEthBalance;
    uint256 public rateChangeLimit;

    address public networkProposalAddress;

    modifier onlyAdmin() {
        require(INetworkProposal(networkProposalAddress).isAdmin(msg.sender), "not admin");
        _;
    }

    function init(address _networkProposalAddress) external override {
        require(!initialized, "already initialized");

        initialized = true;
        version = 1;
        submitBalancesEnabled = true;
        rateChangeLimit = 11e14; //0.0011
        networkProposalAddress = _networkProposalAddress;
    }

    // ------------ getter ------------

    // The block number which balances are current for
    function getBalancesBlock() public view override returns (uint256) {
        return balancesBlock;
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

    // Calculate the amount of ETH backing an amount of lsdToken
    function getEthValue(uint256 _lsdTokenAmount) public view override returns (uint256) {
        // Use 1:1 ratio if no lsdToken is minted
        if (totalLsdTokenSupply == 0) {
            return _lsdTokenAmount;
        }
        // Calculate and return
        return (_lsdTokenAmount * totalEthBalance) / totalLsdTokenSupply;
    }

    // Calculate the amount of lsdToken backed by an amount of ETH
    function getLsdTokenValue(uint256 _ethAmount) public view override returns (uint256) {
        // Use 1:1 ratio if no lsdToken is minted
        if (totalLsdTokenSupply == 0) {
            return _ethAmount;
        }
        // Check network ETH balance
        require(totalEthBalance > 0, "Cannot calculate lsdToken token amount while total network balance is zero");
        // Calculate and return
        return (_ethAmount * totalLsdTokenSupply) / totalEthBalance;
    }

    // Get the current ETH : lsdToken exchange rate
    // Returns the amount of ETH backing 1 lsdToken
    function getExchangeRate() public view override returns (uint256) {
        return getEthValue(1 ether);
    }

    // ------------ settings ------------

    function setRateChangeLimit(uint256 _value) public onlyAdmin {
        rateChangeLimit = _value;
    }

    // ------------ voter ------------

    // Submit network balances for a block
    // Only accepts calls from trusted (oracle) nodes
    function submitBalances(
        uint256 _block,
        uint256 _totalEth,
        uint256 _stakingEth,
        uint256 _lsdTokenSupply
    ) external override {
        bytes32 proposalId = keccak256(
            abi.encodePacked("submitBalances", _block, _totalEth, _stakingEth, _lsdTokenSupply)
        );

        // Emit balances submitted event
        emit BalancesSubmitted(msg.sender, _block, _totalEth, _stakingEth, _lsdTokenSupply, block.timestamp);

        if (INetworkProposal(networkProposalAddress).shouldExecute(proposalId, msg.sender)) {
            require(submitBalancesEnabled, "submitting balances is disabled");
            require(_block > balancesBlock, "network balances for an equal or higher block are set");
            require(_stakingEth <= _totalEth, "invalid network balances");

            uint256 oldRate = getExchangeRate();

            updateBalances(_block, _totalEth, _stakingEth, _lsdTokenSupply);

            uint256 newRate = getExchangeRate();
            uint256 rateChange = newRate > oldRate ? newRate - oldRate : oldRate - newRate;
            require((rateChange * 1e18) / oldRate < rateChangeLimit, "rate change over limit");
        }
    }

    // ------------ helper ------------

    // Update network balances
    function updateBalances(uint256 _block, uint256 _totalEth, uint256 _stakingEth, uint256 _lsdTokenSupply) private {
        // Update balances
        balancesBlock = _block;
        totalEthBalance = _totalEth;
        stakingEthBalance = _stakingEth;
        totalLsdTokenSupply = _lsdTokenSupply;

        // Emit balances updated event
        emit BalancesUpdated(_block, _totalEth, _stakingEth, _lsdTokenSupply, block.timestamp);
    }
}
