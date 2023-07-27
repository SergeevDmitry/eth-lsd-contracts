pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

struct Project {
    uint256 id;
    address rToken;
    address etherKeeper;
    address userDeposit;
    address balances;
    address lightNode;
    address superNode;
    address withdraw;
    address feePool;
    address distributor;
}
