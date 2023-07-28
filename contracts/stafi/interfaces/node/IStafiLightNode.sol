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

    function offBoard(bytes calldata _validatorPubkey) external;

    function voteWithdrawCredentials(
        bytes[] calldata _pubkey,
        bool[] calldata _match
    ) external;
}
