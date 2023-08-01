pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/deposit/IStafiUserDeposit.sol";
import "../interfaces/node/IStafiSuperNode.sol";
import "../interfaces/node/IStafiLightNode.sol";
import "../interfaces/withdraw/IStafiWithdraw.sol";
import "../../project/interfaces/IProjUserDeposit.sol";
import "../../project/interfaces/IProjRToken.sol";

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
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projUserDeposit") == msg.sender,
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
        IProjRToken rETHToken = IProjRToken(
            getContractAddress(_pId, "rETHToken")
        );
        rETHToken.mint(_user, _value);
        projUserDeposit.depositEther(_value);
    }
}
