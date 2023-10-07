pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./IDepositEth.sol";
import "./Errors.sol";
import "./IUpgrade.sol";

interface INetworkWithdraw is IDepositEth, Errors, IUpgrade {
    enum ClaimType {
        None,
        ClaimReward,
        ClaimDeposit,
        ClaimTotal
    }

    enum DistributeType {
        None,
        DistributeWithdrawals,
        DistributePriorityFee
    }

    struct Withdrawal {
        address _address;
        uint256 _amount;
    }

    event NodeClaimed(
        uint256 index,
        address account,
        uint256 claimableReward,
        uint256 claimableDeposit,
        ClaimType claimType
    );
    event SetWithdrawLimitPerCycle(uint256 withdrawLimitPerCycle);
    event SetUserWithdrawLimitPerCycle(uint256 userWithdrawLimitPerCycle);
    event SetWithdrawCycleSeconds(uint256 cycleSeconds);
    event SetMerkleRoot(uint256 indexed dealedEpoch, bytes32 merkleRoot, string nodeRewardsFileCid);
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Unstake(
        address indexed from,
        uint256 lsdTokenAmount,
        uint256 ethAmount,
        uint256 withdrawIndex,
        bool instantly
    );
    event Withdraw(address indexed from, uint256[] withdrawIndexList);
    event DistributeRewards(
        DistributeType distributeType,
        uint256 dealedHeight,
        uint256 userAmount,
        uint256 nodeAmount,
        uint256 platformAmount,
        uint256 maxClaimableWithdrawIndex,
        uint256 mvAmount
    );
    event NotifyValidatorExit(uint256 withdrawCycle, uint256 ejectedStartWithdrawCycle, uint256[] ejectedValidators);

    function init(
        address _lsdTokenAddress,
        address _userDepositAddress,
        address _networkProposalAddress,
        address _networkBalancesAddress,
        address _feePoolAddress,
        address _factoryAddress
    ) external;

    // getter
    function getUnclaimedWithdrawalsOfUser(address _user) external view returns (uint256[] memory);

    function getEjectedValidatorsAtCycle(uint256 _cycle) external view returns (uint256[] memory);

    function totalMissingAmountForWithdraw() external view returns (uint256);

    // user
    function unstake(uint256 _lsdTokenAmount) external;

    function withdraw(uint256[] calldata _withdrawIndexList) external;

    // ejector
    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartWithdrawCycle,
        uint256[] calldata _validatorIndex
    ) external;

    // voter
    function distribute(
        DistributeType _distributeType,
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external;

    function depositEthAndUpdateTotalMissingAmount() external payable;
}
