pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./interfaces/INetworkBalances.sol";
import "./interfaces/ILsdToken.sol";
import "./interfaces/IUserDeposit.sol";

contract LsdToken is ILsdToken, ERC20Burnable {
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

    // Calculate the amount of ETH backing an amount of lsdToken
    function getEthValue(uint256 _lsdTokenAmount) public view returns (uint256) {
        // Get network balances
        INetworkBalances networkBalances = INetworkBalances(networkBalanceAddress);
        uint256 totalEthBalance = networkBalances.getTotalETHBalance();
        uint256 lsdTokenSupply = networkBalances.getTotalLsdTokenSupply();
        // Use 1:1 ratio if no lsdToken is minted
        if (lsdTokenSupply == 0) {
            return _lsdTokenAmount;
        }
        // Calculate and return
        return (_lsdTokenAmount * totalEthBalance) / lsdTokenSupply;
    }

    // Calculate the amount of lsdToken backed by an amount of ETH
    function getLsdTokenValue(uint256 _ethAmount) public view returns (uint256) {
        // Get network balances
        INetworkBalances networkBalances = INetworkBalances(networkBalanceAddress);
        uint256 totalEthBalance = networkBalances.getTotalETHBalance();
        uint256 lsdTokenSupply = networkBalances.getTotalLsdTokenSupply();
        // Use 1:1 ratio if no lsdToken is minted
        if (lsdTokenSupply == 0) {
            return _ethAmount;
        }
        // Check network ETH balance
        require(totalEthBalance > 0, "Cannot calculate lsdToken token amount while total network balance is zero");
        // Calculate and return
        return (_ethAmount * lsdTokenSupply) / totalEthBalance;
    }

    // Get the current ETH : lsdToken exchange rate
    // Returns the amount of ETH backing 1 lsdToken
    function getExchangeRate() public view returns (uint256) {
        return getEthValue(1 ether);
    }

    // Mint lsdToken
    // Only accepts calls from the UserDeposit contract
    function mint(address _to, uint256 _ethAmount) external {
        require(msg.sender == userDepositAddress, "not userDeposit");

        // Get lsdToken amount
        uint256 lsdTokenAmount = getLsdTokenValue(_ethAmount);
        // Check lsdToken amount
        require(lsdTokenAmount > 0, "Invalid token mint amount");
        // Update balance & supply
        _mint(_to, lsdTokenAmount);
        // Emit tokens minted event
        emit TokensMinted(_to, lsdTokenAmount, block.timestamp);
    }
}
