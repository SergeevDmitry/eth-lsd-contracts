pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./interfaces/INetworkBalances.sol";
import "./interfaces/IRToken.sol";
import "./interfaces/IUserDeposit.sol";

// rETH is backed by ETH (subject to liquidity) at a variable exchange rate
contract RToken is IRToken, ERC20Burnable {
    address public userDepositAddress;
    address public networkBalanceAddress;

    // Construct
    constructor(
        address _userDepositAddress,
        address _networkBalanceAddress,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        userDepositAddress = _userDepositAddress;
        networkBalanceAddress = _networkBalanceAddress;
    }

    // Calculate the amount of ETH backing an amount of rETH
    function getEthValue(uint256 _rTokenAmount) public view returns (uint256) {
        // Get network balances
        INetworkBalances networkBalances = INetworkBalances(networkBalanceAddress);
        uint256 totalEthBalance = networkBalances.getTotalETHBalance();
        uint256 rTokenSupply = networkBalances.getTotalRTokenSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rTokenSupply == 0) {
            return _rTokenAmount;
        }
        // Calculate and return
        return (_rTokenAmount * totalEthBalance) / rTokenSupply;
    }

    // Calculate the amount of rETH backed by an amount of ETH
    function getRTokenValue(uint256 _ethAmount) public view returns (uint256) {
        // Get network balances
        INetworkBalances networkBalances = INetworkBalances(networkBalanceAddress);
        uint256 totalEthBalance = networkBalances.getTotalETHBalance();
        uint256 rTokenSupply = networkBalances.getTotalRTokenSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rTokenSupply == 0) {
            return _ethAmount;
        }
        // Check network ETH balance
        require(totalEthBalance > 0, "Cannot calculate rETH token amount while total network balance is zero");
        // Calculate and return
        return (_ethAmount * rTokenSupply) / totalEthBalance;
    }

    // Get the current ETH : rETH exchange rate
    // Returns the amount of ETH backing 1 rETH
    function getExchangeRate() public view returns (uint256) {
        return getEthValue(1 ether);
    }

    // Mint rETH
    // Only accepts calls from the StafiUserDeposit contract
    function mint(address _to, uint256 _ethAmount) external {
        require(msg.sender == userDepositAddress, "not userDeposit");

        // Get rETH amount
        uint256 rethAmount = getRTokenValue(_ethAmount);
        // Check rETH amount
        require(rethAmount > 0, "Invalid token mint amount");
        // Update balance & supply
        _mint(_to, rethAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, rethAmount, block.timestamp);
    }
}
