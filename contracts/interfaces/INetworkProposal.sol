pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface INetworkProposal {
    enum ProposalStatus {
        Inactive,
        Active,
        Executed
    }
    struct Proposal {
        ProposalStatus _status;
        uint16 _yesVotes; // bitmap, 16 maximum votes
        uint8 _yesVotesTotal;
    }

    event VoteProposal(bytes32 indexed proposalId, address voter);
    event ProposalExecuted(bytes32 indexed proposalId);

    function init(address[] memory _voters, uint256 _initialThreshold, address _adminAddress) external;

    function isAdmin(address _sender) external view returns (bool);

    function shouldExecute(bytes32 _proposalId, address _voter) external returns (bool);
}