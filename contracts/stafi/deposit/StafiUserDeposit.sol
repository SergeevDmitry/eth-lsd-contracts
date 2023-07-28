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
            pId > 1 && getContractAddress(pId, "projUserDeposit") == msg.sender,
            "Invalid caller"
        );
        IProjUserDeposit projUserDeposit = IProjUserDeposit(msg.sender);
        require(
            projUserDeposit.getDepositEnabled(),
            "Deposits into Stafi are currently disabled"
        );
        require(
            _value >= projUserDeposit.getMinimumDeposit(),
            "The deposited amount is less than the minimum deposit size"
        );
        IRETHToken rETHToken = IRETHToken(getContractAddress(1, "rETHToken"));
        rETHToken.userMint(pId, _user, _value);
        projUserDeposit.depositEther(_value);
    }
}
