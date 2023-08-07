pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../StafiBase.sol";
import "../interfaces/network/IStafiNetworkBalances.sol";
import "../../project/interfaces/IProjBalances.sol";
import "../../project/interfaces/IProjNodeManager.sol";
import "../../project/interfaces/IProjSettings.sol";

// Network balances
contract StafiNetworkBalances is StafiBase, IStafiNetworkBalances {
    // Libs
    using SafeMath for uint256;

    // Construct
    constructor(address _stafiStorageAddress) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    // Submit network balances for a block
    // Only accepts calls from trusted (oracle) nodes
    function submitBalances(
        address _voter,
        uint256 _block,
        uint256 _totalEth,
        uint256 _stakingEth,
        uint256 _rethSupply
    ) external override onlyLatestContract(1, "stafiNetworkBalances", address(this)) returns (bool) {
        uint256 _pId = getProjectId(msg.sender);
        require(_pId > 1 && getContractAddress(_pId, "projBalances") == msg.sender, "Invalid caller");
        // Check settings
        IProjBalances projBalances = IProjBalances(msg.sender);
        IProjSettings projSettings = IProjSettings(getContractAddress(_pId, "stafiNetworkSettings"));
        require(projSettings.getSubmitBalancesEnabled(), "Submitting balances is currently disabled");
        // Check block
        require(_block > projBalances.getBalancesBlock(), "Network balances for an equal or higher block are set");
        // Check balances
        require(_stakingEth <= _totalEth, "Invalid network balances");
        // Get submission keys
        bytes32 nodeSubmissionKey = keccak256(
            abi.encodePacked(
                "network.balances.submitted.node",
                _pId,
                _voter,
                _block,
                _totalEth,
                _stakingEth,
                _rethSupply
            )
        );
        bytes32 submissionCountKey = keccak256(
            abi.encodePacked("network.balances.submitted.count", _pId, _block, _totalEth, _stakingEth, _rethSupply)
        );
        // Check & update node submission status
        require(!getBool(nodeSubmissionKey), "Duplicate submission from node");
        setBool(nodeSubmissionKey, true);
        setBool(keccak256(abi.encodePacked("network.balances.submitted.node", _pId, _voter, _block)), true);
        // Increment submission count
        uint256 submissionCount = getUint(submissionCountKey).add(1);
        setUint(submissionCountKey, submissionCount);
        // Check submission count & update network balances
        uint256 calcBase = 1 ether;
        IProjNodeManager projNodeManager = IProjNodeManager(getContractAddress(_pId, "projNodeManager"));
        return
            calcBase.mul(submissionCount) >=
            projNodeManager.getTrustedNodeCount().mul(projSettings.getNodeConsensusThreshold());
    }
}
