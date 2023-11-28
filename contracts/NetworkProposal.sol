pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/INetworkProposal.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract NetworkProposal is Initializable, UUPSUpgradeable, INetworkProposal {
    using SafeCast for *;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public admin;
    address public voterManager;

    EnumerableSet.AddressSet voters;
    uint8 public threshold;

    mapping(bytes32 => Proposal) public proposals;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert CallerNotAllowed();
        }
        _;
    }

    modifier onlyVoterManager() {
        if (msg.sender != voterManager) {
            revert CallerNotAllowed();
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function init(address[] memory _voters, uint256 _initialThreshold, address _adminAddress, address _voterManagerAddress)
        public
        virtual
        override
        initializer
    {
        if (_voters.length < _initialThreshold || _initialThreshold <= _voters.length / 2) {
            revert InvalidThreshold();
        }
        if (_adminAddress == address(0)) {
            revert AddressNotAllowed();
        }

        threshold = _initialThreshold.toUint8();
        uint256 initialVoterCount = _voters.length;
        for (uint256 i; i < initialVoterCount; ++i) {
            if (!voters.add(_voters[i])) {
                revert VotersDuplicate();
            }
        }
        admin = _adminAddress;
        voterManager = _voterManagerAddress;
    }

    function reinit() public virtual override reinitializer(1) {
        _reinit();
    }

    function _reinit() internal virtual {}

    function version() external view override returns (uint8) {
        return _getInitializedVersion();
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

    // ------------ settings ------------

    function transferAdmin(address _newAdmin) external onlyAdmin {
        if (_newAdmin == address(0)) {
            revert AddressNotAllowed();
        }

        admin = _newAdmin;
    }

    function transferVoterManager(address _newVoterManager) external onlyVoterManager {
        if (_newVoterManager == address(0)) {
            revert AddressNotAllowed();
        }

        voterManager = _newVoterManager;
    }

    function takeoverVoterManagement(address _newVoterManager, address[] calldata _newVoters, uint256 _threshold) external onlyAdmin {
        if (_newVoterManager == address(0)) {
            revert AddressNotAllowed();
        }

        voterManager = _newVoterManager;
        _replaceVoters(_newVoters, _threshold);
    }

    function replaceVoters(address[] calldata _newVoters, uint256 _threshold) external onlyVoterManager {
        _replaceVoters(_newVoters, _threshold);
    }

    function _replaceVoters(address[] calldata _newVoters, uint256 _threshold) internal {
        if (_newVoters.length < _threshold || _threshold <= _newVoters.length / 2) {
            revert InvalidThreshold();
        }

        // Clear all
        for (uint256 i; i < voters.length(); ++i) {
            voters.remove(voters.at(0));
        }

        for (uint256 i; i < _newVoters.length; ++i) {
            if (!voters.add(_newVoters[i])) {
                revert VotersDuplicate();
            }
        }


        threshold = _threshold.toUint8();
    }

    function addVoter(address _voter) external onlyVoterManager {
        if (threshold <= (voters.length() + 1) / 2) {
            revert InvalidThreshold();
        }

        if (!voters.add(_voter)) {
            revert VotersDuplicate();
        }
    }

    function removeVoter(address _voter) external onlyVoterManager {
        if (voters.length() <= threshold) {
            revert VotersNotEnough();
        }

        if (!voters.remove(_voter)) {
            revert VotersNotExist();
        }
    }

    function changeThreshold(uint256 _newThreshold) external onlyVoterManager {
        if (voters.length() < _newThreshold || _newThreshold <= voters.length() / 2) {
            revert InvalidThreshold();
        }

        threshold = _newThreshold.toUint8();
    }

    function batchExecProposals(
        address[] calldata _tos,
        bytes[] calldata _callDatas,
        uint256[] calldata _proposalFactors
    ) external {
        for (uint256 i = 0; i < _tos.length; i++) {
            execProposal(_tos[i], _callDatas[i], _proposalFactors[i]);
        }
    }

    function execProposal(address _to, bytes calldata _callData, uint256 _proposalFactor) public {
        bytes32 proposalId = keccak256(abi.encodePacked("execProposal", _to, _callData, _proposalFactor));

        if (_shouldExecute(proposalId, msg.sender)) {
            (bool success,) = _to.call(_callData);
            if (!success) {
                revert ProposalExecFailed();
            }

            emit ProposalExecuted(proposalId);
        }
    }

    // ------------ helper ------------

    function voterBit(address _voter) internal view returns (uint256) {
        return uint256(1) << (getVoterIndex(_voter) - 1);
    }

    function _hasVoted(Proposal memory _proposal, address _voter) internal view returns (bool) {
        return (voterBit(_voter) & uint256(_proposal._yesVotes)) > 0;
    }

    function _voteProposal(bytes32 _proposalId, address _voter) internal returns (Proposal memory proposal) {
        proposal = proposals[_proposalId];

        if (!voters.contains(_voter)) {
            revert CallerNotAllowed();
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

    function _shouldExecute(bytes32 _proposalId, address _voter) internal returns (bool) {
        Proposal memory proposal = _voteProposal(_proposalId, _voter);

        if (proposal._status == ProposalStatus.Executed) {
            proposals[_proposalId] = proposal;
            return false;
        }

        if (proposal._yesVotesTotal >= threshold) {
            proposal._status = ProposalStatus.Executed;
            proposals[_proposalId] = proposal;

            return true;
        } else {
            proposals[_proposalId] = proposal;
            return false;
        }
    }
}
