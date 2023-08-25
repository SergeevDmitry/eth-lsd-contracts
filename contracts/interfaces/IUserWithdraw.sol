pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IUserWithdraw {
    struct Withdrawal {
        address _address;
        uint256 _amount;
    }

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Unstake(
        address indexed from,
        uint256 lsdTokenAmount,
        uint256 ethAmount,
        uint256 withdrawIndex,
        bool instantly
    );
    event Withdraw(address indexed from, uint256[] withdrawIndexList);
    event NotifyValidatorExit(uint256 withdrawCycle, uint256 ejectedStartWithdrawCycle, uint256[] ejectedValidators);
    event DistributeWithdrawals(
        uint256 dealedHeight,
        uint256 userAmount,
        uint256 nodeAmount,
        uint256 platformAmount,
        uint256 maxClaimableWithdrawIndex,
        uint256 mvAmount
    );
    event ReserveEthForWithdraw(uint256 withdrawCycle, uint256 mvAmount);
    event SetWithdrawLimitPerCycle(uint256 withdrawLimitPerCycle);
    event SetUserWithdrawLimitPerCycle(uint256 userWithdrawLimitPerCycle);

    function init(
        address _lsdTokenAddress,
        address _userDepositAddress,
        address _distributorAddress,
        address _networkProposalAddress
    ) external;

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
    function distributeWithdrawals(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external;

    function reserveEthForWithdraw(uint256 _withdrawCycle) external;

    function depositEth() external payable;

    function getUnclaimedWithdrawalsOfUser(address user) external view returns (uint256[] memory);

    function getEjectedValidatorsAtCycle(uint256 cycle) external view returns (uint256[] memory);
}
