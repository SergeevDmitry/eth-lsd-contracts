pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "./Errors.sol";
import "./IUpgrade.sol";

interface INetworkProposal is Errors, IUpgrade {
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

    event VoteProposal(bytes32 indexed _proposalId, address _voter);
    event ProposalExecuted(bytes32 indexed _proposalId);

    function init(address[] memory _voters, uint256 _initialThreshold, address _adminAddress) external;

    function isAdmin(address _sender) external view returns (bool);
}
