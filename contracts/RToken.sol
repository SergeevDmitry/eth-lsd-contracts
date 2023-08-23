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

    // Events
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 time);

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
    function getEthValue(uint256 _rethAmount) public view returns (uint256) {
        // Get network balances
        INetworkBalances projNetworkBalances = INetworkBalances(networkBalanceAddress);
        uint256 totalEthBalance = projNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = projNetworkBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) {
            return _rethAmount;
        }
        // Calculate and return
        return (_rethAmount * totalEthBalance) / rethSupply;
    }

    // Calculate the amount of rETH backed by an amount of ETH
    function getRethValue(uint256 _ethAmount) public view returns (uint256) {
        // Get network balances
        INetworkBalances projBalances = INetworkBalances(networkBalanceAddress);
        uint256 totalEthBalance = projBalances.getTotalETHBalance();
        uint256 rethSupply = projBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) {
            return _ethAmount;
        }
        // Check network ETH balance
        require(totalEthBalance > 0, "Cannot calculate rETH token amount while total network balance is zero");
        // Calculate and return
        return (_ethAmount * rethSupply) / totalEthBalance;
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
        uint256 rethAmount = getRethValue(_ethAmount);
        // Check rETH amount
        require(rethAmount > 0, "Invalid token mint amount");
        // Update balance & supply
        _mint(_to, rethAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, rethAmount, block.timestamp);
    }
}
