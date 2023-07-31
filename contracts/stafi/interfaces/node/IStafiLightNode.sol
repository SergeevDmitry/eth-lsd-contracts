pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiLightNode {
    function depositEth() external payable;

    function deposit(
        address _user,
        uint256 _value,
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external;

    function stake(
        address _user,
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external;

    function offBoard(address _user, bytes calldata _validatorPubkey) external;

    function provideNodeDepositToken(
        uint256 _value,
        bytes calldata _validatorPubkey
    ) external payable;

    function withdrawNodeDepositToken(
        address _user,
        bytes calldata _validatorPubkey
    ) external;

    function voteWithdrawCredentials(
        address _voter,
        bytes[] calldata _pubkeys,
        bool[] calldata _matchs
    ) external;
}
