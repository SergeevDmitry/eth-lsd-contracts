pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../stafi/StafiBase.sol";
import "./interfaces/IProjEther.sol";
import "./interfaces/IProjFeePool.sol";
import "./interfaces/IProjUserDeposit.sol";

// receive priority fee
contract ProjFeePool is StafiBase, IProjFeePool {
    // Libs
    using SafeMath for uint256;

    // Events
    event EtherWithdrawn(
        string indexed by,
        address indexed to,
        uint256 amount,
        uint256 time
    );

    // Construct
    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        // Version
        version = 1;
    }

    function ProjUserDeposit() private view returns (IProjUserDeposit) {
        return IProjUserDeposit(getContractAddress(pId, "projUserDeposit"));
    }

    // Allow receiving ETH
    receive() external payable {}

    function depositEther(
        uint256 _value
    )
        public
        onlyLatestContract(pId, "projFeePool", address(this))
        onlyLatestContract(1, "stafiDistributor", msg.sender)
    {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.depositEther{value: _value}();
    }

    function recycleUserDeposit(
        uint256 _value
    )
        external
        override
        onlyLatestContract(pId, "projFeePool", address(this))
        onlyLatestContract(1, "stafiDistributor", msg.sender)
    {
        ProjUserDeposit().recycleDistributorDeposit{value: _value}();
    }
}
