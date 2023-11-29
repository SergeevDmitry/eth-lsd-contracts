pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "forge-std/Test.sol";
import {DepositContract} from "contracts/mock/EthDeposit.sol";
import {LsdToken} from "contracts/LsdToken.sol";
import {NodeDeposit} from "contracts/NodeDeposit.sol";
import {UserDeposit} from "contracts/UserDeposit.sol";
import {NetworkProposal} from "contracts/NetworkProposal.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract MockNetworkProposal is NetworkProposal {
    using EnumerableSet for EnumerableSet.AddressSet;
    function getVoters() public view returns (address[] memory) {
        uint256 length = voters.length();
        address[] memory list = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = voters.at(i);
        }
        return list;
    }
}

contract NodeProposalTest is Test {
    LsdToken lt;
    NodeDeposit nd;
    MockNetworkProposal np;
    address admin;
    address[] voters;
    address ethDepositAddress;

    function setUp() public {
        np = MockNetworkProposal(address(new ERC1967Proxy(address(new MockNetworkProposal()), "")));
        voters = new address[](3);
        voters[0] = address(1);
        voters[1] = address(2);
        voters[2] = address(3);
        admin = address(4);
        np.init(voters, 2, admin, admin);
    }

    function test_ReplaceVoters() public {
        vm.startPrank(admin);
        address[] memory newVoters = new address[](3);
        newVoters[0] = address(11);
        newVoters[1] = address(12);
        newVoters[2] = address(13);
        np.replaceVoters(newVoters, 3);
        assertEq(np.threshold(), 3);
        address[] memory gotVoters = np.getVoters();
        assertEq(newVoters.length, gotVoters.length);
        assertEq(newVoters[0], gotVoters[0]);
        assertEq(newVoters[1], gotVoters[1]);
        assertEq(newVoters[2], gotVoters[2]);
    }
}
