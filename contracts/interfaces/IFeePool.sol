pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "./Errors.sol";
import "./Common.sol";

interface IFeePool is Errors, Common {
    event EtherWithdrawn(uint256 amount, uint256 time);

    function init(address _networkWithdrawAddress, address _networkProposalAddress) external;

    function withdrawEther(uint256 _amount) external;
}
