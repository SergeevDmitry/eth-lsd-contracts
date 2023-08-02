pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiWithdraw {
    // user

    function unstake(address _user, uint256 _rEthAmount) external;

    function withdraw(
        address _user,
        uint256[] calldata _withdrawIndexList
    ) external;

    // ejector
    function notifyValidatorExit(
        address _voter,
        uint256 _withdrawCycle,
        uint256 _ejectedStartWithdrawCycle,
        uint256[] calldata _validatorIndex
    ) external;

    // voter
    function distributeWithdrawals(
        address _voter,
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external;

    function reserveEthForWithdraw(
        address _voter,
        uint256 _withdrawCycle
    ) external;

    function getUnclaimedWithdrawalsOfUser(
        uint256 _pId,
        address user
    ) external view returns (uint256[] memory);

    function getEjectedValidatorsAtCycle(
        uint256 _pId,
        uint256 cycle
    ) external view returns (uint256[] memory);

    function setWithdrawLimitPerCycle(uint256 _withdrawLimitPerCycle) external;

    function setUserWithdrawLimitPerCycle(
        uint256 _userWithdrawLimitPerCycle
    ) external;

    // project withdraw
    function depositCommission() external payable;
}
