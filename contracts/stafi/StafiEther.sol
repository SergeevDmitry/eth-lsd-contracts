pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StafiBase.sol";
import "./interfaces/IStafiEther.sol";

// ETH are stored here to prevent contract upgrades from affecting balances
// The contract must not be upgraded
contract StafiEther is StafiBase, IStafiEther {
    // Libs
    using SafeMath for uint256;

    // Contract balances
    mapping(uint256 => uint256) commissions;

    // Events
    event CommissionDeposited(uint256 indexed pId, uint256 amount, uint256 time);
    event EtherWithdrawn(bytes32 indexed by, uint256 amount, uint256 time);

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    function commissionOf(uint256 _pId) public view returns (uint256) {
        return commissions[_pId];
    }

    function depositCommission(uint256 _pId) external payable override {
        commissions[_pId] = commissions[_pId].add(msg.value);
        emit CommissionDeposited(_pId, msg.value, block.timestamp);
    }

    function withdrawEther(uint256 _amount) external onlySuperUser(1) {
        payable(msg.sender).transfer(_amount);
    }
}
