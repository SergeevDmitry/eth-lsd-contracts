pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../Timelock.sol";
import "../LsdToken.sol";

library NewContractLib {
    function newTimelock(
        uint256 minDelay, address[] memory proposers, address[] memory executors, address admin
    ) public returns (address) {
        return address(new Timelock(minDelay, proposers, executors, admin));
    }

    function newERC1967Proxy(address _logicAddress) public returns (address) {
        return address(new ERC1967Proxy(_logicAddress, ""));
    }

    function newLsdToken(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol
    ) public returns (address) {
        return address(new LsdToken(_lsdTokenName, _lsdTokenSymbol));
    }
}
