pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./interfaces/ILsdToken.sol";
import "./interfaces/IUserDeposit.sol";

contract LsdToken is ILsdToken, ERC20Burnable {
    address public userDepositAddress;

    // Construct
    constructor(address _userDepositAddress, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        userDepositAddress = _userDepositAddress;
    }

    function getRate() external view returns (uint256) {
        return IUserDeposit(userDepositAddress).getRate();
    }

    // Mint lsdToken
    // Only accepts calls from the UserDeposit contract
    function mint(address _to, uint256 _lsdTokenAmount) external {
        if (msg.sender != userDepositAddress) {
            revert CallerNotAllowed();
        }
        // Check lsdToken amount
        if (_lsdTokenAmount == 0) {
            revert AmountZero();
        }
        // Update balance & supply
        _mint(_to, _lsdTokenAmount);
    }
}
