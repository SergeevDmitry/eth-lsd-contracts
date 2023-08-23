pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface IProposalType {
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

    event ProposalExecuted(bytes32 indexed proposalId);
    event VoteProposal(bytes32 indexed proposalId, address voter);
}
