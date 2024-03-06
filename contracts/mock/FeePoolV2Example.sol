// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "../FeePool.sol";

// receive priority fee
contract FeePoolV2Example is FeePool {
    string public NewVarV2;

    // called by factory
    function init(address _networkWithdrawAddress, address _networkProposalAddress) public virtual override {
        super.init(_networkWithdrawAddress, _networkProposalAddress);
        _reinit();
    }

    // called by anyone after upgrade
    function reinit() public virtual override reinitializer(2) {
        _reinit();
    }

    function _reinit() internal virtual override {
        NewVarV2 = "new var v2";
    }
}
