pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StafiBase.sol";

abstract contract StafiVoteBase is StafiBase {
    using SafeMath for uint256;

    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {}

    function _voteThreshold(
        uint256 _pId
    ) internal view virtual returns (uint256) {
        return 2 ether;
    }

    function _voteProposal(
        uint256 _pId,
        address _voter,
        bytes32 _proposalId,
        bool _position
    ) internal returns (bool) {
        string memory contractName = getContractName(_pId, address(this));
        // Get submission keys
        bytes32 proposalNodeKey = keccak256(
            abi.encodePacked(
                contractName,
                "proposal.node.key",
                _pId,
                _proposalId,
                _voter
            )
        );
        bytes32 proposalKey = keccak256(
            abi.encodePacked(contractName, "proposal.key", _pId, _proposalId)
        );

        bytes32 proposalPositionKey = keccak256(
            abi.encodePacked(
                contractName,
                "proposal.position.key",
                _pId,
                _proposalId,
                _position
            )
        );

        require(!getBool(proposalKey), "proposal already executed");

        // Check & update node submission status
        require(!getBool(proposalNodeKey), "duplicate vote");
        setBool(proposalNodeKey, true);

        // Increment submission count
        uint256 voteCount = getUint(proposalPositionKey).add(1);
        setUint(proposalPositionKey, voteCount);

        // Check submission count & update network balances
        uint256 calcBase = 1 ether;
        if (calcBase.mul(voteCount) >= _voteThreshold(_pId)) {
            setBool(proposalKey, true);
            return true;
        }
        return false;
    }
}
