pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INodeDeposit.sol";
import "./interfaces/IRToken.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/IUserWithdraw.sol";

contract UserDeposit is IUserDeposit {
    event DepositReceived(address indexed from, uint256 amount, uint256 time);
    event DepositRecycled(address indexed from, uint256 amount, uint256 time);
    event ExcessWithdrawn(address indexed to, uint256 amount, uint256 time);

    bool public depositEnabled;
    uint256 public minDeposit;
    bool public initialized;
    address public admin;
    address public rTokenAddress;
    address public nodeDepositAddress;
    address public userWithdrawAddress;
    address public distributorAddress;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Invalid admin");
        _;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setDepositEnabled(bool _value) public onlyAdmin {
        depositEnabled = _value;
    }

    function setMinimumDeposit(uint256 _value) public onlyAdmin {
        minDeposit = _value;
    }

    function deposit() external payable override {
        require(depositEnabled, "Deposits into Stafi are currently disabled");
        require(msg.value >= minDeposit, "The deposited amount is less than the minimum deposit size");
        IRToken(rTokenAddress).mint(msg.sender, msg.value);
    }

    // Withdraw excess deposit pool balance for light node
    function withdrawExcessBalanceForNodeDeposit(uint256 _amount) external override {
        require(msg.sender == nodeDepositAddress, "not lightNode");
        // Check amount
        require(_amount <= getBalance(), "Insufficient balance for withdrawal");
        // Transfer to lightNode contract
        INodeDeposit(nodeDepositAddress).depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Withdraw excess deposit pool balance for withdraw
    function withdrawExcessBalanceForUserWithdraw(uint256 _amount) external override {
        require(msg.sender == userWithdrawAddress, "not withdraw");
        // Check amount
        require(_amount <= getBalance(), "Insufficient balance for withdrawal");
        // Transfer to withdraw contract
        IUserWithdraw(userWithdrawAddress).depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Recycle a deposit from fee collector
    // Only accepts calls from registered stafiDistributor
    function recycleDistributorDeposit() external payable override {
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
    }

    // Recycle a deposit from withdraw
    // Only accepts calls from registered stafiWithdraw
    function recycleWithdrawDeposit() external payable override {
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
    }
}
