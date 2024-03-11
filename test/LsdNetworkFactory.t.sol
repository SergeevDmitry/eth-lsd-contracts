// SPDX-License-Identifier: GPL-3.0-and-later
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {LsdNetworkFactory} from "contracts/LsdNetworkFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract LsdNetworkFactoryTest is Test {

    function test_ClaimStackFee() public {
        address admin = address(100);
        vm.startPrank(admin);
        LsdNetworkFactory factory = LsdNetworkFactory(payable(address(new ERC1967Proxy(address(new LsdNetworkFactory()), ""))));
        factory.init(admin, address(1), address(1), address(1), address(1), address(1), address(1), address(1));
        vm.deal(address(factory), 2 ether);
        address recipient = address(101);
        assertEq(factory.totalClaimedStackFee(), 0);
        factory.factoryClaim(recipient, 1 ether);
        assertEq(factory.totalClaimedStackFee(), 1 ether);
        factory.factoryClaim(recipient, 1 ether);
        assertEq(factory.totalClaimedStackFee(), 2 ether);
        vm.expectRevert();
        factory.factoryClaim(recipient, 1 ether);
    }
}
