// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import "./FeePoolV2Example.sol";

// receive priority fee
contract FeePoolV3Example is FeePoolV2Example {
    string public NewVarV3;

    // called by factory
    function init(address _networkWithdrawAddress, address _networkProposalAddress) public virtual override {
        super.init(_networkWithdrawAddress, _networkProposalAddress);
        _reinit();
    }

    // called by anyone after upgrade
    function reinit() public virtual override reinitializer(3) {
        _reinit();
    }

    function _reinit() internal virtual override {
        NewVarV3 = "new var v3";
    }
}
