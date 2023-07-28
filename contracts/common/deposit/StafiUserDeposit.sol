pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/IStafiEtherWithdrawer.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/token/IRETHToken.sol";
import "../interfaces/node/IStafiSuperNode.sol";
import "../interfaces/node/IStafiLightNode.sol";
import "../interfaces/withdraw/IStafiWithdraw.sol";
import "../../project/interfaces/IProjUserDeposit.sol";

// Accepts user deposits and mints rETH; handles assignment of deposited ETH to pools
contract StafiUserDeposit is StafiBase, IStafiUserDeposit {
    // Libs
    using SafeMath for uint256;

    // Events
    event DepositReceived(address indexed from, uint256 amount, uint256 time);
    event DepositRecycled(address indexed from, uint256 amount, uint256 time);
    event ExcessWithdrawn(address indexed to, uint256 amount, uint256 time);

    // Construct
    constructor(
        address _stafiStorageAddress
    ) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    // Accept a deposit from a user
    function deposit(
        address _user,
        uint256 _value
    )
        external
        override
        onlyLatestContract(1, "stafiUserDeposit", address(this))
    {
        uint256 pId = getProjectId(msg.sender);
        require(
            pId > 0 && getContractAddress(pId, "projUserDeposit") == msg.sender,
            "Invalid caller"
        );
        require(
            getDepositEnabled(),
            "Deposits into Stafi are currently disabled"
        );
        require(
            _value >= getMinimumDeposit(),
            "The deposited amount is less than the minimum deposit size"
        );
        IRETHToken rETHToken = IRETHToken(getContractAddress(1, "rETHToken"));
        rETHToken.userMint(pId, _user, _value);
        processDeposit(_value);
    }

    function processDeposit(uint256 _value) private {
        IProjUserDeposit projUserDeposit = IProjUserDeposit(msg.sender);
        projUserDeposit.depositEther(_value);
    }

    function getDepositEnabled() public view returns (bool) {
        IProjUserDeposit projUserDeposit = IProjUserDeposit(msg.sender);
        return projUserDeposit.getDepositEnabled();
    }

    function getMinimumDeposit() public view returns (uint256) {
        IProjUserDeposit projUserDeposit = IProjUserDeposit(msg.sender);
        return projUserDeposit.getMinimumDeposit();
    }
}
