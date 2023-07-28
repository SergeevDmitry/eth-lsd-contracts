pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProjEther {
    function balanceOf(
        address _contractAddress
    ) external view returns (uint256);

    function depositEther() external payable;

    function withdrawEther(uint256 _amount) external;
}
