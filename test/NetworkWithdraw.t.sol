pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "forge-std/Test.sol";
import {DepositContract} from "contracts/mock/EthDeposit.sol";
import {LsdToken} from "contracts/LsdToken.sol";
import {NodeDeposit} from "contracts/NodeDeposit.sol";
import {UserDeposit} from "contracts/UserDeposit.sol";
import {NetworkWithdraw} from "contracts/NetworkWithdraw.sol";
import {NetworkProposal} from "contracts/NetworkProposal.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NetworkWithdrawTest is Test {

    function test_SetStackCommissionRate() public {
        NetworkProposal np = NetworkProposal(address(new ERC1967Proxy(address(new NetworkProposal()), "")));
        address[] memory voters = new address[](1);
        voters[0] = address(1);
        address admin = address(4);
        np.init(voters, 1, admin, admin);

        NetworkWithdraw nw = NetworkWithdraw(payable(address(new ERC1967Proxy(address(new NetworkWithdraw()), ""))));

        nw.init(
            address(0),
            address(0),
            address(np),
            address(0),
            address(0),
            address(0)
        );

        vm.startPrank(admin);
        assertEq(nw.stackCommissionRate(), 10e16);
        nw.setStackCommissionRate(10e16+1e16);
        assertEq(nw.stackCommissionRate(), 10e16+1e16);
    }
}
