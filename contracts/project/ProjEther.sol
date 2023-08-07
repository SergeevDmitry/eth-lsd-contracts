pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../stafi/StafiBase.sol";
import "./interfaces/IProjEther.sol";
import "./interfaces/IProjEtherWithdrawer.sol";

// ETH are stored here to prevent contract upgrades from affecting balances
// The contract must not be upgraded
contract ProjEther is StafiBase, IProjEther {
    // Libs
    using SafeMath for uint256;

    // Contract balances
    mapping(bytes32 => uint256) balances;

    // Events
    event EtherDeposited(bytes32 indexed by, uint256 amount, uint256 time);
    event EtherWithdrawn(bytes32 indexed by, uint256 amount, uint256 time);

    // Construct
    constructor(uint256 _pId, address _stafiStorageAddress) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
    }

    // Get a contract's ETH balance by address
    function balanceOf(address _contractAddress) public view override returns (uint256) {
        return balances[keccak256(abi.encodePacked(getContractName(pId, _contractAddress)))];
    }

    // Accept an ETH deposit from a network contract
    function depositEther() external payable override onlyLatestProjectContract(pId) {
        // Get contract key
        bytes32 contractKey = keccak256(abi.encode(getContractName(pId, msg.sender)));
        // Update contract balance
        balances[contractKey] = balances[contractKey].add(msg.value);
        // Emit ether deposited event
        emit EtherDeposited(contractKey, msg.value, block.timestamp);
    }

    // Withdraw an amount of ETH to a network contract
    function withdrawEther(uint256 _amount) external override onlyLatestProjectContract(pId) {
        // Get contract key
        bytes32 contractKey = keccak256(abi.encode(getContractName(pId, msg.sender)));
        // Check and update contract balance
        require(balances[contractKey] >= _amount, "Insufficient contract ETH balance");
        balances[contractKey] = balances[contractKey].sub(_amount);
        // Withdraw
        IProjEtherWithdrawer withdrawer = IProjEtherWithdrawer(msg.sender);
        withdrawer.receiveEtherWithdrawal{value: _amount}();
        // Emit ether withdrawn event
        emit EtherWithdrawn(contractKey, _amount, block.timestamp);
    }
}
