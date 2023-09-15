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
        if (initialized) {
            revert AlreadyInitialized();
        }

        initialized = true;
        version = 1;
        networkWithdrawAddress = _networkWithdrawAddress;
    }

    // Allow receiving ETH
    receive() external payable {}

    // Withdraws ETH to given address
    // Only accepts calls from network contracts
    function withdrawEther(uint256 _amount) external override {
        if (_amount == 0) {
            revert AmountZero();
        }
        if (msg.sender != networkWithdrawAddress) {
            revert CallerNotAllowed();
        }

        IDepositEth(msg.sender).depositEth{value: _amount}();

        // Emit ether withdrawn event
        emit EtherWithdrawn(_amount, block.timestamp);
    }
}
