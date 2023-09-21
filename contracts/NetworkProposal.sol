pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/INetworkProposal.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract NetworkProposal is UUPSUpgradeable, INetworkProposal {
    using SafeCast for *;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public initialized;
    uint8 public version;
    uint8 public threshold;
    address public admin;

    EnumerableSet.AddressSet voters;
    mapping(bytes32 => Proposal) public proposals;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert NotNetworkAdmin();
        }
        _;
    }

    function init(address[] memory _voters, uint256 _initialThreshold, address _adminAddress) public {
        if (initialized) {
            revert AlreadyInitialized();
        }
        if (_voters.length < _initialThreshold || _initialThreshold <= _voters.length / 2) {
            revert InvalidThreshold();
        }
        if (_voters.length > 16) {
            revert VoterNumberOverLimit();
        }
        if (_adminAddress == address(0)) {
            revert AddressNotAllowed();
        }

        initialized = true;
        version = 1;
        threshold = _initialThreshold.toUint8();
        uint256 initialVoterCount = _voters.length;
        for (uint256 i; i < initialVoterCount; ++i) {
            if (!voters.add(_voters[i])) {
                revert VotersDuplicate();
            }
        }
        admin = _adminAddress;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    // ------------ getter ------------

    function getVoterIndex(address _voter) public view returns (uint256) {
        return voters._inner._indexes[bytes32(uint256(uint160(_voter)))];
    }

    function hasVoted(bytes32 _proposalId, address _voter) public view returns (bool) {
        Proposal memory proposal = proposals[_proposalId];
        return _hasVoted(proposal, _voter);
    }

    function isVoter(address _sender) external view returns (bool) {
        return voters.contains(_sender);
    }

    function isAdmin(address _sender) external view returns (bool) {
        return admin == _sender;
    }

    function shouldExecute(bytes32 _proposalId, address _voter) external override returns (bool) {
        Proposal memory proposal = _checkProposal(_proposalId, _voter);
        if (proposal._yesVotesTotal >= threshold) {
            proposal._status = ProposalStatus.Executed;
            proposals[_proposalId] = proposal;
            emit ProposalExecuted(_proposalId);
            return true;
        } else {
            proposals[_proposalId] = proposal;
            return false;
        }
    }

    // ------------ settings ------------

    function transferAdmin(address _newAdmin) public onlyAdmin {
        if (_newAdmin == address(0)) {
            revert AddressNotAllowed();
        }

        admin = _newAdmin;
    }

    function addVoter(address _voter) public onlyAdmin {
        if (voters.length() >= 16) {
            revert VoterNumberOverLimit();
        }
        if (threshold <= (voters.length() + 1) / 2) {
            revert InvalidThreshold();
        }

        if (!voters.add(_voter)) {
            revert VotersDuplicate();
        }
    }

    function removeVoter(address _voter) public onlyAdmin {
        if (voters.length() <= threshold) {
            revert VotersNotEnough();
        }

        if (!voters.remove(_voter)) {
            revert VotersNotExist();
        }
    }

    function changeThreshold(uint256 _newThreshold) external onlyAdmin {
        if (voters.length() < _newThreshold || _newThreshold <= voters.length() / 2) {
            revert InvalidThreshold();
        }

        threshold = _newThreshold.toUint8();
    }

    // ------------ helper ------------

    function voterBit(address _voter) internal view returns (uint256) {
        return uint256(1) << (getVoterIndex(_voter) - 1);
    }

    function _hasVoted(Proposal memory _proposal, address _voter) internal view returns (bool) {
        return (voterBit(_voter) & uint256(_proposal._yesVotes)) > 0;
    }

    function _checkProposal(bytes32 _proposalId, address _voter) internal returns (Proposal memory proposal) {
        proposal = proposals[_proposalId];

        if (!voters.contains(_voter)) {
            revert CallerNotAllowed();
        }
        if (proposal._status != ProposalStatus.Inactive && proposal._status != ProposalStatus.Active) {
            revert ProposalAlreadyExecuted();
        }
        if (_hasVoted(proposal, _voter)) {
            revert AlreadyVoted();
        }

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status: ProposalStatus.Active, _yesVotes: 0, _yesVotesTotal: 0});
        }
        proposal._yesVotes = (proposal._yesVotes | voterBit(_voter)).toUint16();
        proposal._yesVotesTotal++;

        emit VoteProposal(_proposalId, _voter);
    }
}
