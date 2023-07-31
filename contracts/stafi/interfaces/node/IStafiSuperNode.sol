pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

interface IStafiSuperNode {
    function deposit(
        address _user,
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

    function getSuperNodePubkeyCount(
        uint256 _pId,
        address _nodeAddress
    ) external view returns (uint256);

    function getSuperNodePubkeyStatus(
        uint256 _pId,
        bytes calldata _validatorPubkey
    ) external view returns (uint256);

    function voteWithdrawCredentials(
        address _voter,
        bytes[] calldata _pubkeys,
        bool[] calldata _matchs
    ) external;
}
