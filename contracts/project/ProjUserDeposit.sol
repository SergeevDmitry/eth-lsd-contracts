pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../common/StafiBase.sol";
import "../common/interfaces/deposit/IStafiUserDeposit.sol";
import "./interfaces/IProjEther.sol";
import "./interfaces/IProjUserDeposit.sol";

contract UserDeposit is StafiBase, IProjUserDeposit {
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

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

    function getBalance() external view returns (uint256) {
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
        uint256 value
    ) external onlyLatestContract(0, "stafiUserDeposit", msg.sender) {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.depositEther{value: value}();
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
}
