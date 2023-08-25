pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INodeDeposit.sol";
import "./interfaces/ILsdToken.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/IUserWithdraw.sol";
import "./interfaces/INetworkProposal.sol";

contract UserDeposit is IUserDeposit {
    bool public initialized;
    uint8 public version;
    bool public depositEnabled;

    uint256 public minDeposit;

    address public lsdTokenAddress;
    address public nodeDepositAddress;
    address public userWithdrawAddress;
    address public distributorAddress;
    address public networkProposalAddress;

    modifier onlyAdmin() {
        require(INetworkProposal(networkProposalAddress).isAdmin(msg.sender), "not admin");
        _;
    }

    function init(
        address _lsdTokenAddress,
        address _nodeDepositAddress,
        address _userWithdrawAddress,
        address _distributorAddress,
        address _networkProposalAddress
    ) external override {
        require(!initialized, "already initialized");

        initialized = true;
        version = 1;
        depositEnabled = true;
        lsdTokenAddress = _lsdTokenAddress;
        nodeDepositAddress = _nodeDepositAddress;
        userWithdrawAddress = _userWithdrawAddress;
        distributorAddress = _distributorAddress;
        networkProposalAddress = _networkProposalAddress;
    }

    // ------------ getter ------------

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // ------------ settings ------------

    function setDepositEnabled(bool _value) public onlyAdmin {
        depositEnabled = _value;
    }

    function setMinimumDeposit(uint256 _value) public onlyAdmin {
        minDeposit = _value;
    }

    // ------------ user ------------

    function deposit() external payable override {
        require(depositEnabled, "deposit  disabled");
        require(msg.value >= minDeposit, "deposit amount is less than the minimum deposit size");

        ILsdToken(lsdTokenAddress).mint(msg.sender, msg.value);
    }

    // ------------ network ------------

    // Withdraw excess deposit pool balance
    function withdrawExcessBalanceForNodeDeposit(uint256 _amount) external override {
        require(msg.sender == nodeDepositAddress, "not nodeDeposit");
        // Check amount
        require(_amount <= getBalance(), "insufficient balance for withdrawal");
        INodeDeposit(nodeDepositAddress).depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Withdraw excess deposit pool balance for withdraw
    function withdrawExcessBalanceForUserWithdraw(uint256 _amount) external override {
        require(msg.sender == userWithdrawAddress, "not userWithdraw");
        // Check amount
        require(_amount <= getBalance(), "insufficient balance for withdrawal");
        // Transfer to withdraw contract
        IUserWithdraw(userWithdrawAddress).depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Recycle a deposit from fee collector
    // Only accepts calls from distributor
    function recycleDistributorDeposit() external payable override {
        require(msg.sender == distributorAddress, "not distributor");

        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
    }

    // Recycle a deposit from withdraw
    // Only accepts calls from  userWithdraw
    function recycleWithdrawDeposit() external payable override {
        require(msg.sender == userWithdrawAddress, "not userWithdraw");
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
    }
}
