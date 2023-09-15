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
    uint256 public rateChangeLimit;

    address public networkProposalAddress;

    modifier onlyAdmin() {
        if (!INetworkProposal(networkProposalAddress).isAdmin(msg.sender)) {
            revert NotNetworkAdmin();
        }
        _;
    }

    function init(address _networkProposalAddress) external override {
        if (initialized) {
            revert AlreadyInitialized();
        }

        initialized = true;
        version = 1;
        submitBalancesEnabled = true;
        rateChangeLimit = 11e14; //0.0011
        networkProposalAddress = _networkProposalAddress;
    }

    // ------------ getter ------------

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
        if (totalEthBalance == 0) {
            revert AmountZero();
        }
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
    function submitBalances(uint256 _block, uint256 _totalEth, uint256 _lsdTokenSupply) external override {
        bytes32 proposalId = keccak256(abi.encodePacked("submitBalances", _block, _totalEth, _lsdTokenSupply));

        // Emit balances submitted event
        emit BalancesSubmitted(msg.sender, _block, _totalEth, _lsdTokenSupply, block.timestamp);

        if (INetworkProposal(networkProposalAddress).shouldExecute(proposalId, msg.sender)) {
            if (!submitBalancesEnabled) {
                revert SubmitBalancesDisable();
            }
            if (_block <= balancesBlock) {
                revert BlockNotMatch();
            }

            uint256 oldRate = getExchangeRate();

            updateBalances(_block, _totalEth, _lsdTokenSupply);

            uint256 newRate = getExchangeRate();
            uint256 rateChange = newRate > oldRate ? newRate - oldRate : oldRate - newRate;
            if ((rateChange * 1e18) / oldRate > rateChangeLimit) {
                revert RateChangeOverLimit();
            }
        }
    }

    // ------------ helper ------------

    // Update network balances
    function updateBalances(uint256 _block, uint256 _totalEth, uint256 _lsdTokenSupply) private {
        // Update balances
        balancesBlock = _block;
        totalEthBalance = _totalEth;
        totalLsdTokenSupply = _lsdTokenSupply;

        // Emit balances updated event
        emit BalancesUpdated(_block, _totalEth, _lsdTokenSupply, block.timestamp);
    }
}
