pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "../stafi/interfaces/withdraw/IStafiWithdraw.sol";
import "./interfaces/IProjDistributor.sol";
import "./interfaces/IProjUserDeposit.sol";
import "./interfaces/IProjWithdraw.sol";

contract ProjWithdraw is StafiBase, IProjWithdraw {
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event SetWithdrawLimitPerCycle(uint256 withdrawLimitPerCycle);
    event SetUserWithdrawLimitPerCycle(uint256 userWithdrawLimitPerCycle);

    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {}

    function ProjUserDeposit() private view returns (IProjUserDeposit) {
        return IProjUserDeposit(getContractAddress(pId, "projUserDeposit"));
    }

    function ProjDistributor() private view returns (IProjDistributor) {
        return IProjDistributor(getContractAddress(pId, "projDistributor"));
    }

    // Deposit ETH from deposit pool
    // Only accepts calls from the ProjUserDeposit contract
    function depositEth()
        external
        payable
        override
        onlyLatestContract(pId, "projUserDeposit", msg.sender)
    {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function unstake(
        uint256 _rEthAmount
    ) external onlyLatestContract(pId, "projWithdraw", address(this)) {
        IStafiWithdraw stafiWithdraw = IStafiWithdraw(
            getContractAddress(1, "stafiWithdraw")
        );
        stafiWithdraw.unstake(msg.sender, _rEthAmount);
    }

    function withdraw(
        uint256[] calldata _withdrawIndexList
    ) external onlyLatestContract(pId, "projWithdraw", address(this)) {
        IStafiWithdraw stafiWithdraw = IStafiWithdraw(
            getContractAddress(1, "stafiWithdraw")
        );
        stafiWithdraw.withdraw(msg.sender, _withdrawIndexList);
    }

    function doWithdraw(
        address _user,
        uint256 _amount
    ) external onlyLatestContract(1, "stafiWithdraw", msg.sender) {
        (bool result, ) = _user.call{value: _amount}("");
        require(result, "user failed to withdraw ETH");
    }

    function recycleUserDeposit(
        uint256 _value
    ) external onlyLatestContract(1, "stafiWithdraw", msg.sender) {
        ProjUserDeposit().recycleDistributorDeposit{value: _value}();
    }

    function doDistributeWithdrawals(
        uint256 _value
    ) external onlyLatestContract(1, "stafiWithdraw", msg.sender) {
        ProjDistributor().distributeWithdrawals{value: _value}();
    }

    function distributeWithdrawals(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    )
        external
        onlyLatestContract(pId, "projWithdraw", address(this))
        onlySuperUser(pId)
    {
        IStafiWithdraw stafiWithdraw = IStafiWithdraw(
            getContractAddress(1, "stafiWithdraw")
        );
        stafiWithdraw.distributeWithdrawals(
            msg.sender,
            _dealedHeight,
            _userAmount,
            _nodeAmount,
            _platformAmount,
            _maxClaimableWithdrawIndex
        );
    }

    function withdrawCommission(
        uint256 _value
    ) external override onlyLatestContract(1, "stafiWithdraw", msg.sender) {
        IStafiWithdraw(msg.sender).depositCommission{value: _value}();
    }

    function reserveEthForWithdraw(
        uint256 _withdrawCycle
    )
        external
        onlyLatestContract(pId, "projWithdraw", address(this))
        onlySuperUser(pId)
    {
        IStafiWithdraw stafiWithdraw = IStafiWithdraw(
            getContractAddress(1, "stafiWithdraw")
        );
        stafiWithdraw.reserveEthForWithdraw(msg.sender, _withdrawCycle);
    }

    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartCycle,
        uint256[] calldata _validatorIndexList
    )
        external
        onlyLatestContract(pId, "projWithdraw", address(this))
        onlySuperUser(pId)
    {
        IStafiWithdraw stafiWithdraw = IStafiWithdraw(
            getContractAddress(1, "stafiWithdraw")
        );
        stafiWithdraw.notifyValidatorExit(
            msg.sender,
            _withdrawCycle,
            _ejectedStartCycle,
            _validatorIndexList
        );
    }

    function setWithdrawLimitPerCycle(
        uint256 _withdrawLimitPerCycle
    ) external onlySuperUser(pId) {
        IStafiWithdraw stafiWithdraw = IStafiWithdraw(
            getContractAddress(1, "stafiWithdraw")
        );
        stafiWithdraw.setWithdrawLimitPerCycle(_withdrawLimitPerCycle);
        emit SetWithdrawLimitPerCycle(_withdrawLimitPerCycle);
    }

    function setUserWithdrawLimitPerCycle(
        uint256 _userWithdrawLimitPerCycle
    ) external onlySuperUser(pId) {
        IStafiWithdraw stafiWithdraw = IStafiWithdraw(
            getContractAddress(1, "stafiWithdraw")
        );
        stafiWithdraw.setUserWithdrawLimitPerCycle(_userWithdrawLimitPerCycle);

        emit SetUserWithdrawLimitPerCycle(_userWithdrawLimitPerCycle);
    }
}
