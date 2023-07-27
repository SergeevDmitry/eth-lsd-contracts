pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjUserDeposit {
    function depositEther(uint256) external;

    function getBalance() external view returns (uint256);
}
