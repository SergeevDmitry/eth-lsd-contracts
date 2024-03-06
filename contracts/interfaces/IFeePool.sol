// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "./Errors.sol";
import "./IUpgrade.sol";

interface IFeePool is Errors, IUpgrade {
    event EtherWithdrawn(uint256 amount, uint256 time);

    function init(address _networkWithdrawAddress, address _networkProposalAddress) external;

    function withdrawEther(uint256 _amount) external;
}
