// pragma solidity 0.8.19;

// // SPDX-License-Identifier: GPL-3.0-only

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "../StafiBase.sol";
// import "../interfaces/reward/IStafiFeePool.sol";

// // receive priority fee
// contract StafiFeePool is StafiBase, IStafiFeePool {
//     // Libs
//     using SafeMath for uint256;

//     // Events
//     event EtherWithdrawn(
//         string indexed by,
//         address indexed to,
//         uint256 amount,
//         uint256 time
//     );

//     // Construct
//     constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {
//         // Version
//         version = 1;
//     }

//     // Allow receiving ETH
//     receive() external payable {}

//     // Withdraws ETH to given address
//     // Only accepts calls from network contracts
//     function withdrawEther(
//         address _to,
//         uint256 _amount
//     ) external override onlyLatestNetworkContract {
//         // Valid amount?
//         require(_amount > 0, "No valid amount of ETH given to withdraw");
//         // Get contract name
//         string memory contractName = getContractName(msg.sender);
//         // Send the ETH
//         (bool result, ) = _to.call{value: _amount}("");
//         require(result, "Failed to withdraw ETH");
//         // Emit ether withdrawn event
//         emit EtherWithdrawn(contractName, _to, _amount, block.timestamp);
//     }
// }
