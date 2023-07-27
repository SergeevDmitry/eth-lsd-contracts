pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/token/IRETHToken.sol";
import "../../project/interfaces/IProjBalances.sol";
import "../../project/interfaces/IProjRToken.sol";

// rETH is backed by ETH (subject to liquidity) at a variable exchange rate
contract RETHToken is StafiBase, IRETHToken {
    // Libs
    using SafeMath for uint256;

    // Events
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(
        address indexed to,
        uint256 pId,
        uint256 amount,
        uint256 ethAmount,
        uint256 time
    );
    event TokensBurned(
        address indexed from,
        uint256 pId,
        uint256 amount,
        uint256 ethAmount,
        uint256 time
    );

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    // Calculate the amount of ETH backing an amount of rETH
    function getEthValue(
        uint256 _pId,
        uint256 _rethAmount
    ) public view returns (uint256) {
        // Get network balances
        IProjBalances stafiNetworkBalances = IProjBalances(
            getContractAddress(_pId, "stafiNetworkBalances")
        );
        uint256 totalEthBalance = stafiNetworkBalances.getTotalETHBalance();
        uint256 rethSupply = stafiNetworkBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) {
            return _rethAmount;
        }
        // Calculate and return
        return _rethAmount.mul(totalEthBalance).div(rethSupply);
    }

    // Calculate the amount of rETH backed by an amount of ETH
    function getRethValue(
        uint256 _pId,
        uint256 _ethAmount
    ) public view returns (uint256) {
        // Get network balances
        IProjBalances projBalances = IProjBalances(
            getContractAddress(_pId, "stafiNetworkBalances")
        );
        uint256 totalEthBalance = projBalances.getTotalETHBalance();
        uint256 rethSupply = projBalances.getTotalRETHSupply();
        // Use 1:1 ratio if no rETH is minted
        if (rethSupply == 0) {
            return _ethAmount;
        }
        // Check network ETH balance
        require(
            totalEthBalance > 0,
            "Cannot calculate rETH token amount while total network balance is zero"
        );
        // Calculate and return
        return _ethAmount.mul(rethSupply).div(totalEthBalance);
    }

    // Get the current ETH : rETH exchange rate
    // Returns the amount of ETH backing 1 rETH
    function getExchangeRate(uint256 _pId) public view returns (uint256) {
        return getEthValue(_pId, 1 ether);
    }

    // Mint rETH
    // Only accepts calls from the StafiUserDeposit contract
    function userMint(
        uint256 _pId,
        address _to,
        uint256 _ethAmount
    ) external override onlyLatestContract(0, "stafiUserDeposit", msg.sender) {
        // Get rETH amount
        uint256 rethAmount = getRethValue(_pId, _ethAmount);
        // Check rETH amount
        require(rethAmount > 0, "Invalid token mint amount");

        IProjRToken projRToken = IProjRToken(
            getContractAddress(_pId, "projrToken")
        );
        // Update balance & supply
        projRToken.mint(_to, rethAmount);

        // Emit tokens minted event
        emit TokensMinted(_to, _pId, rethAmount, _ethAmount, block.timestamp);
    }
}
