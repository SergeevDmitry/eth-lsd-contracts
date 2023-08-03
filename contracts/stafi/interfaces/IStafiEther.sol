pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiEther {
    function depositCommission(uint256 _pId) external payable;
}
