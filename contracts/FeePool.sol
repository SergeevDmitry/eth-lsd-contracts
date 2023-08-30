pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/IFeePool.sol";
import "./interfaces/IDepositEth.sol";

// receive priority fee
contract FeePool is IFeePool {
    bool public initialized;
    uint8 public version;

    address public networkWithdrawAddress;

    function init(address _networkWithdrawAddress) external override {
        require(!initialized, "already initialized");

        initialized = true;
        version = 1;
        networkWithdrawAddress = _networkWithdrawAddress;
    }

    // Allow receiving ETH
    receive() external payable {}

    // Withdraws ETH to given address
    // Only accepts calls from network contracts
    function withdrawEther(uint256 _amount) external override {
        require(_amount > 0, "No valid amount of ETH given to withdraw");
        require(msg.sender == networkWithdrawAddress, "not networkWithdrawAddress");

        IDepositEth(msg.sender).depositEth{value: _amount}();

        // Emit ether withdrawn event
        emit EtherWithdrawn(_amount, block.timestamp);
    }
}
