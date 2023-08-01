pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjUserDeposit {
    function depositEther(uint256) external;

    function getBalance() external view returns (uint256);

    function getDepositEnabled() external view returns (bool);

    function getMinimumDeposit() external view returns (uint256);

    function withdrawExcessBalance(uint256 _amount) external;

    function withdrawExcessBalanceForSuperNode(uint256 _amount) external;

    function withdrawExcessBalanceForLightNode(uint256 _amount) external;

    // function withdrawExcessBalanceForWithdraw(uint256 _amount) external;

    function recycleDistributorDeposit() external payable;
}
