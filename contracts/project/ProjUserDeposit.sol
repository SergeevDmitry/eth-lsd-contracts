pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../common/interfaces/deposit/IStafiUserDeposit.sol";
import "../common/interfaces/IProjEther.sol";
import "./interfaces/IProjUserDeposit.sol";
import "./ProjContract.sol";

contract UserDeposit is ProjContract, IProjUserDeposit {
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) ProjContract(_pId, _stafiStorageAddress) {}

    function getBalance() external view returns (uint256) {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        return projEther.balanceOf(address(this));
    }

    function deposit() external payable {
        IStafiUserDeposit stafiUserDeposit = IStafiUserDeposit(
            getContractAddress(0, "stafiUserDeposit")
        );
        stafiUserDeposit.deposit(msg.sender, msg.value);
    }

    function depositEther(
        uint256 value
    ) external onlyLatestContract(0, "stafiUserDeposit", msg.sender) {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.depositEther{value: value}();
    }

    function setDepositEnabled(bool _value) public onlySuperUser(pId) {
        setBool(keccak256(abi.encode("settings.deposit.enabled", pId)), _value);
    }

    function setMinimumDeposit(uint256 _value) public onlySuperUser(pId) {
        setUint(keccak256(abi.encode("settings.deposit.minimum", pId)), _value);
    }
}
