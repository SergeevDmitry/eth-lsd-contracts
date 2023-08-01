pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "../../types/ClaimType.sol";

interface IStafiDistributor {
    function updateMerkleRoot(bytes32 _merkleRoot) external;

    function distributeFee(
        address _voter,
        uint256 _dealedHeight,
        uint256 _totalAmount
    ) external;

    function distributeSuperNodeFee(
        address _voter,
        uint256 _dealedHeight,
        uint256 _totalAmount
    ) external;

    function distributeSlashAmount(
        address _voter,
        uint256 _dealedHeight,
        uint256 _amount
    ) external;

    function setMerkleRoot(
        address _voter,
        uint256 _dealedEpoch,
        bytes32 _merkleRoot
    ) external;

    function claim(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount,
        bytes32[] calldata _merkleProof,
        ClaimType _claimType
    ) external;
}
