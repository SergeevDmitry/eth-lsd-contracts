pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "./Errors.sol";

interface IFeePool is Errors {
    event EtherWithdrawn(uint256 amount, uint256 time);

    function init(address _networkWithdrawAddress, address _networkProposalAddress) external;

    function withdrawEther(uint256 _amount) external;
}
