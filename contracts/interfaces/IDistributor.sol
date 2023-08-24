pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IDistributor {
    enum ClaimType {
        None,
        ClaimReward,
        ClaimDeposit,
        ClaimTotal
    }

    event Claimed(
        uint256 index,
        address account,
        uint256 claimableReward,
        uint256 claimableDeposit,
        ClaimType claimType
    );

    event DistributeFee(uint256 dealedHeight, uint256 userAmount, uint256 nodeAmount, uint256 platformAmount);
    event DistributeSuperNodeFee(uint256 dealedHeight, uint256 userAmount, uint256 nodeAmount, uint256 platformAmount);
    event DistributeSlash(uint256 dealedHeight, uint256 slashAmount);
    event SetMerkleRoot(uint256 dealedEpoch, bytes32 merkleRoot);

    function distributeWithdrawals() external payable;
}
