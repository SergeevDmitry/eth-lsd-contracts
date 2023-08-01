pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "../stafi/interfaces/deposit/IStafiUserDeposit.sol";
import "./interfaces/IProjEther.sol";
import "./interfaces/IProjEtherWithdrawer.sol";
import "./interfaces/IProjLightNode.sol";
import "./interfaces/IProjRToken.sol";
import "./interfaces/IProjSuperNode.sol";
import "./interfaces/IProjUserDeposit.sol";
import "./interfaces/IProjWithdraw.sol";

contract UserDeposit is StafiBase, IProjUserDeposit, IProjEtherWithdrawer {
    event DepositReceived(address indexed from, uint256 amount, uint256 time);
    event DepositRecycled(address indexed from, uint256 amount, uint256 time);
    event ExcessWithdrawn(address indexed to, uint256 amount, uint256 time);

    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        if (
            !getBool(keccak256(abi.encode("settings.user.deposit.init", _pId)))
        ) {
            // Apply settings
            setDepositEnabled(true);
            setMinimumDeposit(0.01 ether);
            // Settings initialized
            setBool(
                keccak256(abi.encode("settings.user.deposit.init", _pId)),
                true
            );
        }
    }

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal()
        external
        payable
        override
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyLatestContract(pId, "projEther", msg.sender)
    {}

    function getBalance() public view returns (uint256) {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        return projEther.balanceOf(address(this));
    }

    function deposit() external payable {
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(
            getContractAddress(1, "stafiUserDeposit")
        );
        stafiUserDeposit.deposit(msg.sender, msg.value);
    }

    function depositEther(
        uint256 _value
    )
        public
        onlyLatestContract(pId, "projUserDeposit", address(this))
        onlyLatestStackContract(pId)
    {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.depositEther{value: _value}();
    }

    // Withdraw excess deposit pool balance for super node
    function withdrawExcessBalanceForSuperNode(
        uint256 _amount
    )
        external
        override
        onlyLatestContract(pId, "projUserDeposit", address(this))
        onlyLatestContract(1, "stafiSuperNode", msg.sender)
    {
        // Load contracts
        IProjSuperNode superNode = IProjSuperNode(
            getContractAddress(pId, "projSuperNode")
        );
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        // Check amount
        require(_amount <= getBalance(), "Insufficient balance for withdrawal");
        // Withdraw ETH from vault
        projEther.withdrawEther(_amount);
        // Transfer to superNode contract
        superNode.depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Withdraw excess deposit pool balance for light node
    function withdrawExcessBalanceForLightNode(
        uint256 _amount
    )
        external
        override
        onlyLatestContract(pId, "projUserDeposit", address(this))
        onlyLatestContract(1, "stafiLightNode", msg.sender)
    {
        // Load contracts
        IProjLightNode lightNode = IProjLightNode(
            getContractAddress(pId, "projLightNode")
        );
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        // Check amount
        require(_amount <= getBalance(), "Insufficient balance for withdrawal");
        // Withdraw ETH from vault
        projEther.withdrawEther(_amount);
        // Transfer to superNode contract
        lightNode.depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Withdraw excess deposit pool balance for withdraw
    function withdrawExcessBalanceForWithdraw(
        uint256 _amount
    )
        external
        override
        onlyLatestContract(pId, "projUserDeposit", address(this))
        onlyLatestContract(1, "stafiWithdraw", msg.sender)
    {
        // Load contracts
        IProjWithdraw projWithdraw = IProjWithdraw(
            getContractAddress(pId, "projWithdraw")
        );
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        // Check amount
        require(_amount <= getBalance(), "Insufficient balance for withdrawal");
        // Withdraw ETH from vault
        projEther.withdrawEther(_amount);
        // Transfer to superNode contract
        projWithdraw.depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    function getDepositEnabled() public view returns (bool) {
        return getBool(keccak256(abi.encode("settings.deposit.enabled", pId)));
    }

    function getMinimumDeposit() public view returns (uint256) {
        return getUint(keccak256(abi.encode("settings.deposit.minimum", pId)));
    }

    function setDepositEnabled(bool _value) public onlySuperUser(pId) {
        setBool(keccak256(abi.encode("settings.deposit.enabled", pId)), _value);
    }

    function setMinimumDeposit(uint256 _value) public onlySuperUser(pId) {
        setUint(keccak256(abi.encode("settings.deposit.minimum", pId)), _value);
    }

    // Recycle a deposit from fee collector
    // Only accepts calls from registered stafiDistributor
    function recycleDistributorDeposit()
        external
        payable
        override
        onlyLatestContract(pId, "projUserDeposit", address(this))
        onlyLatestContract(pId, "projFeePool", msg.sender)
    {
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        // Process deposit
        depositEther(msg.value);
    }

    // Recycle a deposit from withdraw
    // Only accepts calls from registered stafiWithdraw
    function recycleWithdrawDeposit()
        external
        payable
        override
        onlyLatestContract(pId, "projUserDeposit", address(this))
        onlyLatestContract(pId, "projFeePool", msg.sender)
    {
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
        // Process deposit
        depositEther(msg.value);
    }
}
