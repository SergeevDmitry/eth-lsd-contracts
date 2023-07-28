pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../common/StafiBase.sol";
import "../common/interfaces/deposit/IStafiUserDeposit.sol";
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

    // Deposit ETH rewards
    // Only accepts calls from the StafiNetworkWithdrawal contract
    function depositRewards()
        external
        payable
        onlyLatestContract(pId, "stafiNetworkWithdrawal", msg.sender)
    {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Deposit excess ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositExcess()
        external
        payable
        onlyLatestContract(pId, "stafiUserDeposit", msg.sender)
    {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // Mint rETH
    // Only accepts calls from the StafiUserDeposit contract
    function mint(
        address _to,
        uint256 _rethAmount
    ) external onlyLatestContract(1, "RETHToken", msg.sender) {
        // Check rETH amount
        require(_rethAmount > 0, "Invalid token mint amount");
        // Update balance & supply
        _mint(_to, _rethAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, _rethAmount, block.timestamp);
    }
}
