pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "./interfaces/IProjSuperNode.sol";

contract ProjSuperNode is StafiBase, IProjSuperNode {
    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
    }

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth()
        external
        payable
        override
        onlyLatestContract(pId, "projUserDeposit", msg.sender)
    {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }
}
