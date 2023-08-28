pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/INetworkProposal.sol";

contract NetworkProposal is INetworkProposal {
    using SafeCast for *;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public initialized;
    uint8 public version;
    uint8 public threshold;
    address public admin;

    EnumerableSet.AddressSet voters;
    mapping(bytes32 => Proposal) public proposals;

    modifier onlyAdmin() {
        require(admin == msg.sender, "caller is not the admin");
        _;
    }

    function init(address[] memory _voters, uint256 _initialThreshold, address _adminAddress) public {
        require(!initialized, "already initialized");
        require(_voters.length >= _initialThreshold && _initialThreshold > _voters.length / 2, "invalid threshold");
        require(_voters.length <= 16, "too much voters");
        require(_adminAddress != address(0), "not valid address");

        initialized = true;
        version = 1;
        threshold = _initialThreshold.toUint8();
        uint256 initialVoterCount = _voters.length;
        for (uint256 i; i < initialVoterCount; ++i) {
            voters.add(_voters[i]);
        }
        admin = _adminAddress;
    }

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
        require(_newAdmin != address(0), "zero address");

        admin = _newAdmin;
    }

    function addVoter(address _voter) public onlyAdmin {
        require(voters.length() < 16, "too much voters");
        require(threshold > (voters.length() + 1) / 2, "invalid threshold");

        voters.add(_voter);
    }

    function removeVoter(address _voter) public onlyAdmin {
        require(voters.length() > threshold, "voters not enough");

        voters.remove(_voter);
    }

    function changeThreshold(uint256 _newThreshold) external onlyAdmin {
        require(voters.length() >= _newThreshold && _newThreshold > voters.length() / 2, "invalid threshold");

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

        require(voters.contains(_voter), "not voter");
        require(
            proposal._status == ProposalStatus.Inactive || proposal._status == ProposalStatus.Active,
            "proposal already executed"
        );
        require(!_hasVoted(proposal, _voter), "already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status: ProposalStatus.Active, _yesVotes: 0, _yesVotesTotal: 0});
        }
        proposal._yesVotes = (proposal._yesVotes | voterBit(_voter)).toUint16();
        proposal._yesVotesTotal++;

        emit VoteProposal(_proposalId, _voter);
    }
}
