pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/INetworkProposal.sol";

contract NetworkProposal is INetworkProposal {
    using SafeCast for *;
    using EnumerableSet for EnumerableSet.AddressSet;

    bool public initialized;
    uint8 public threshold;
    address public admin;

    EnumerableSet.AddressSet voters;
    mapping(bytes32 => Proposal) public proposals;

    modifier onlyVoter() {
        require(voters.contains(msg.sender));
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "caller is not the owner");
        _;
    }

    function init(address[] memory _voters, uint256 _initialThreshold, address adminAddress) public {
        require(!initialized, "already initialized");
        require(_voters.length >= _initialThreshold && _initialThreshold > _voters.length / 2, "invalid threshold");
        require(_voters.length <= 16, "too much voters");
        require(adminAddress != address(0), "not valid address");

        initialized = true;
        threshold = _initialThreshold.toUint8();
        uint256 initialVoterCount = _voters.length;
        for (uint256 i; i < initialVoterCount; ++i) {
            voters.add(_voters[i]);
        }
        admin = adminAddress;
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

    function checkProposal(bytes32 _proposalId) external returns (Proposal memory, uint8) {
        return (_checkProposal(_proposalId), threshold);
    }

    function saveProposal(bytes32 _proposalId, Proposal calldata proposal) external {
        proposals[_proposalId] = proposal;
    }

    // ------------ settings ------------

    function transferOwnership(address _newOwner) public onlyAdmin {
        require(_newOwner != address(0), "zero address");

        admin = _newOwner;
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

    function _checkProposal(bytes32 _proposalId) internal returns (Proposal memory proposal) {
        proposal = proposals[_proposalId];

        require(uint256(proposal._status) <= 1, "proposal already executed");
        require(!_hasVoted(proposal, msg.sender), "already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({_status: ProposalStatus.Active, _yesVotes: 0, _yesVotesTotal: 0});
        }
        proposal._yesVotes = (proposal._yesVotes | voterBit(msg.sender)).toUint16();
        proposal._yesVotesTotal++;

        emit VoteProposal(_proposalId, msg.sender);
    }
}
