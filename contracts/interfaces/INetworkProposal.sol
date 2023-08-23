pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "./IProposalType.sol";

interface INetworkProposal is IProposalType {
    function isVoter(address _sender) external view returns (bool);

    function isAdmin(address _sender) external view returns (bool);

    function checkProposal(bytes32 _proposalId) external returns (Proposal memory proposal, uint8 threshold);

    function saveProposal(bytes32 _proposalId, Proposal calldata _proposal) external;
}
