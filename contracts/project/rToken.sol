pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../stafi/StafiBase.sol";
import "../stafi/interfaces/deposit/IStafiUserDeposit.sol";
import "./interfaces/IProjBalances.sol";
import "./interfaces/IProjRToken.sol";
import "./interfaces/IProjUserDeposit.sol";

// rETH is backed by ETH (subject to liquidity) at a variable exchange rate
contract rToken is StafiBase, ERC20Burnable, IProjRToken {
    // Libs
    using SafeMath for uint256;

    // Events
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 time);

    // Construct
    constructor(
        uint256 _pId,
        address _stafiStorageAddress,
        string memory name,
        string memory symbol
    ) StafiBase(_pId, _stafiStorageAddress) ERC20(name, symbol) {
        version = 1;
    }

    // Calculate the amount of ETH backing an amount of rETH
    function getEthValue(uint256 _rethAmount) public view returns (uint256) {
        // Get network balances
        IProjBalances projNetworkBalances = IProjBalances(getContractAddress(pId, "stafiNetworkBalances"));
        uint256 totalEthBalance = projNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = projNetworkBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) {
            return _rethAmount;
        }
        // Calculate and return
        return _rethAmount.mul(totalEthBalance).div(rethSupply);
    }

    // Calculate the amount of rETH backed by an amount of ETH
    function getRethValue(uint256 _ethAmount) public view returns (uint256) {
        // Get network balances
        IProjBalances projBalances = IProjBalances(getContractAddress(pId, "stafiNetworkBalances"));
        uint256 totalEthBalance = projBalances.getTotalETHBalance();
        uint256 rethSupply = projBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) {
            return _ethAmount;
        }
        // Check network ETH balance
        require(totalEthBalance > 0, "Cannot calculate rETH token amount while total network balance is zero");
        // Calculate and return
        return _ethAmount.mul(rethSupply).div(totalEthBalance);
    }

    // Get the current ETH : rETH exchange rate
    // Returns the amount of ETH backing 1 rETH
    function getExchangeRate() public view returns (uint256) {
        return getEthValue(1 ether);
    }

    // Deposit ETH rewards
    // Only accepts calls from the StafiNetworkWithdrawal contract
    function depositRewards() external payable onlyLatestContract(pId, "stafiNetworkWithdrawal", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Deposit excess ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositExcess() external payable onlyLatestContract(pId, "stafiUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Mint rETH
    // Only accepts calls from the StafiUserDeposit contract
    function mint(
        address _to,
        uint256 _ethAmount
    )
        external
        onlyLatestContract(pId, "projRToken", address(this))
        onlyLatestContract(1, "stafiUserDeposit", msg.sender)
    {
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
