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
    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
        version = 1;
    }

    // Accept a deposit from a user
    function deposit(
        address _user,
        uint256 _value
    )
        external
        override
        onlyLatestContract(0, "stafiUserDeposit", address(this))
    {
        uint256 pId = getProjectId(msg.sender);
        // Check called by project user deposit
        require(pId > 0, "Invalid caller");
        // Check deposit settings
        require(
            getDepositEnabled(pId),
            "Deposits into Stafi are currently disabled"
        );
        require(
            _value >= getMinimumDeposit(pId),
            "The deposited amount is less than the minimum deposit size"
        );
        // Load contracts
        IRETHToken rETHToken = IRETHToken(getContractAddress(0, "rETHToken"));
        // Mint rETH to user account
        rETHToken.userMint(pId, _user, _value);
        // Process deposit
        processDeposit(_value);
    }

    // Process a deposit
    function processDeposit(uint256 _value) private {
        IProjUserDeposit projUserDeposit = IProjUserDeposit(msg.sender);
        projUserDeposit.depositEther(_value);
    }

    // Deposits currently enabled
    function getDepositEnabled(uint256 _projectId) public view returns (bool) {
        return
            getBool(
                keccak256(abi.encode("settings.deposit.enabled", _projectId))
            );
    }

    // Minimum deposit size
    function getMinimumDeposit(
        uint256 _projectId
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(abi.encode("settings.deposit.minimum", _projectId))
            );
    }
}
