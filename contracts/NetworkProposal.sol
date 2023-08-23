pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/INetworkProposal.sol";
import "./ProposalBase.sol";

contract NetworkProposal is ProposalBase, INetworkProposal {
    bool public initialized;

    function initialize() public {
        require(!initialized, "already initialized");
        // Settings initialized
        initialized = true;
    }

    function isVoter(address _sender) external view returns (bool) {
        return _isVoter(_sender);
    }

    function isAdmin(address _sender) external view returns (bool) {
        return _isAdmin(_sender);
    }

    function checkProposal(bytes32 _proposalId) external returns (Proposal memory, uint8) {
        return (_checkProposal(_proposalId), threshold);
    }

    function saveProposal(bytes32 _proposalId, Proposal calldata proposal) external {
        proposals[_proposalId] = proposal;
    }
}
