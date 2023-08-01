pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../StafiBase.sol";
import "../interfaces/reward/IStafiDistributor.sol";
import "../interfaces/settings/IStafiNetworkSettings.sol";
import "../types/ClaimType.sol";
import "../../project/interfaces/IProjDistributor.sol";
import "../../project/interfaces/IProjFeePool.sol";
import "../../project/interfaces/IProjNodeManager.sol";
import "../../project/interfaces/IProjSettings.sol";

// Distribute network validator priorityFees/withdrawals/slashs
contract StafiDistributor is StafiBase, IStafiDistributor {
    // Libs
    using SafeMath for uint256;

    event Claimed(
        uint256 index,
        address account,
        uint256 claimableReward,
        uint256 claimableDeposit,
        ClaimType claimType
    );
    event VoteProposal(bytes32 indexed proposalId, uint256 pId, address voter);
    event ProposalExecuted(bytes32 indexed proposalId, uint256 pId);
    event DistributeFee(uint256 pId, uint256 dealedHeight, uint256 totalAmount);
    event DistributeSuperNodeFee(
        uint256 pId,
        uint256 dealedHeight,
        uint256 totalAmount
    );
    event DistributeSlash(
        uint256 pId,
        uint256 dealedHeight,
        uint256 slashAmount
    );
    event SetMerkleRoot(uint256 pId, uint256 dealedEpoch, bytes32 merkleRoot);

    // Construct
    constructor(
        address _stafiStorageAddress
    ) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    function StafiNetworkSettings()
        private
        view
        returns (IStafiNetworkSettings)
    {
        return
            IStafiNetworkSettings(
                getContractAddress(1, "stafiNetworkSettings")
            );
    }

    function ProjectSettings(
        uint256 _pId
    ) private view returns (IProjSettings) {
        return IProjSettings(getContractAddress(_pId, "projSettings"));
    }

    function ProjectNodeManager(
        uint256 _pId
    ) private view returns (IProjNodeManager) {
        return IProjNodeManager(getContractAddress(_pId, "projNodeManager"));
    }

    // ------------ getter ------------

    function getCurrentNodeDepositAmount(
        uint256 _pId
    ) public view returns (uint256) {
        return ProjectSettings(_pId).getCurrentNodeDepositAmount();
    }

    function getMerkleDealedEpoch(uint256 _pId) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "stafiDistributor.merkleRoot.dealedEpoch",
                        _pId
                    )
                )
            );
    }

    function getTotalClaimedReward(
        uint256 _pId,
        address _account
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "stafiDistributor.node.totalClaimedReward",
                        _pId,
                        _account
                    )
                )
            );
    }

    function getTotalClaimedDeposit(
        uint256 _pId,
        address _account
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "stafiDistributor.node.totalClaimedDeposit",
                        _pId,
                        _account
                    )
                )
            );
    }

    function getMerkleRoot(uint256 _pId) public view returns (bytes32) {
        return
            getBytes32(
                keccak256(abi.encodePacked("stafiDistributor.merkleRoot", _pId))
            );
    }

    function getDistributeFeeDealedHeight(
        uint256 _pId
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "stafiDistributor.distributeFee.dealedHeight",
                        _pId
                    )
                )
            );
    }

    function getDistributeSuperNodeFeeDealedHeight(
        uint256 _pId
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "stafiDistributor.distributeSuperNodeFee.dealedHeight",
                        _pId
                    )
                )
            );
    }

    function getDistributeSlashDealedHeight(
        uint256 _pId
    ) public view returns (uint256) {
        return
            getUint(
                keccak256(
                    abi.encodePacked(
                        "stafiDistributor.distributeSlashAmount.dealedHeight",
                        _pId
                    )
                )
            );
    }

    // ------------ settings ------------

    function updateMerkleRoot(
        bytes32 _merkleRoot
    ) external onlyLatestContract(1, "stafiDistributor", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projDistributor") == msg.sender,
            "Invalid caller"
        );
        setMerkleRoot(_pId, _merkleRoot);
    }

    // ------------ vote ------------

    // v2: platform = 5%  node = 5% + (90% * nodedeposit/32) user = 90%*(1-nodedeposit/32)
    // distribute fee of feePool for user/node/platform
    function distributeFee(
        address _voter,
        uint256 _dealedHeight,
        uint256 _totalAmount
    ) external onlyLatestContract(1, "stafiDistributor", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projDistributor") == msg.sender,
            "Invalid caller"
        );
        require(_totalAmount > 0, "zero amount");

        require(
            _dealedHeight > getDistributeFeeDealedHeight(_pId),
            "height already dealed"
        );

        bytes32 proposalId = keccak256(
            abi.encodePacked("distributeFee", _pId, _dealedHeight, _totalAmount)
        );
        bool needExe = _voteProposal(_pId, _voter, proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            uint256 protocolCommission = _totalAmount
                .mul(StafiNetworkSettings().getPlatformFeePercent())
                .div(1000);
            uint256 projTotalAmount = _totalAmount.sub(protocolCommission);
            uint256 userAmount = projTotalAmount
                .mul(ProjectSettings(_pId).getDistributeFeeUserPercent())
                .mul(32 - ProjectSettings(_pId).getCurrentNodeDepositAmount())
                .div(32000);
            uint256 nodeAndPlatformAmount = projTotalAmount.sub(userAmount);
            IProjFeePool feePool = IProjFeePool(msg.sender);

            if (userAmount > 0) {
                feePool.recycleUserDeposit(userAmount);
            }
            if (nodeAndPlatformAmount > 0) {
                feePool.depositEther(nodeAndPlatformAmount);
            }

            setDistributeFeeDealedHeight(_pId, _dealedHeight);

            _afterExecProposal(_pId, proposalId);
        }
    }

    // v1: platform = 10% node = 9%  user = 81%
    // distribute fee of superNode feePool for user/node/platform
    function distributeSuperNodeFee(
        address _voter,
        uint256 _dealedHeight,
        uint256 _totalAmount
    ) external onlyLatestContract(1, "stafiDistributor", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projDistributor") == msg.sender,
            "Invalid caller"
        );

        require(_totalAmount > 0, "zero amount");

        require(
            _dealedHeight > getDistributeSuperNodeFeeDealedHeight(_pId),
            "height already dealed"
        );

        bytes32 proposalId = keccak256(
            abi.encodePacked(
                "distributeSuperNodeFee",
                _dealedHeight,
                _totalAmount
            )
        );
        bool needExe = _voteProposal(_pId, _voter, proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            uint256 protocolCommission = _totalAmount
                .mul(StafiNetworkSettings().getPlatformFeePercent())
                .div(1000);
            uint256 projTotalAmount = _totalAmount.sub(protocolCommission);
            uint256 userAmount = projTotalAmount
                .mul(
                    ProjectSettings(_pId).getDistributeSuperNodeFeeUserPercent()
                )
                .div(1000);
            uint256 nodeAndPlatformAmount = projTotalAmount.sub(userAmount);

            IProjFeePool feePool = IProjFeePool(msg.sender);
            if (userAmount > 0) {
                feePool.recycleUserDeposit(userAmount);
            }
            if (nodeAndPlatformAmount > 0) {
                feePool.depositEther(nodeAndPlatformAmount);
            }

            setDistributeSuperNodeFeeDealedHeight(_pId, _dealedHeight);

            _afterExecProposal(_pId, proposalId);
        }
    }

    // distribute slash amount for user
    function distributeSlashAmount(
        address _voter,
        uint256 _dealedHeight,
        uint256 _amount
    ) external onlyLatestContract(1, "stafiDistributor", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projDistributor") == msg.sender,
            "Invalid caller"
        );

        require(_amount > 0, "zero amount");

        require(
            _dealedHeight > getDistributeSlashDealedHeight(_pId),
            "height already dealed"
        );

        bytes32 proposalId = keccak256(
            abi.encodePacked(
                "distributeSlashAmount",
                _pId,
                _dealedHeight,
                _amount
            )
        );
        bool needExe = _voteProposal(_pId, _voter, proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            IProjFeePool feePool = IProjFeePool(msg.sender);
            feePool.recycleUserDeposit(_amount);

            setDistributeSlashDealedHeight(_pId, _dealedHeight);

            _afterExecProposal(_pId, proposalId);

            emit DistributeSlash(_pId, _dealedHeight, _amount);
        }
    }

    function setMerkleRoot(
        address _voter,
        uint256 _dealedEpoch,
        bytes32 _merkleRoot
    ) external onlyLatestContract(1, "stafiDistributor", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projDistributor") == msg.sender,
            "Invalid caller"
        );

        uint256 predealedEpoch = getMerkleDealedEpoch(_pId);
        require(_dealedEpoch > predealedEpoch, "epoch already dealed");

        bytes32 proposalId = keccak256(
            abi.encodePacked("setMerkleRoot", _pId, _dealedEpoch, _merkleRoot)
        );
        bool needExe = _voteProposal(_pId, _voter, proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            setMerkleRoot(_pId, _merkleRoot);
            setMerkleDealedEpoch(_pId, _dealedEpoch);

            _afterExecProposal(_pId, proposalId);

            emit SetMerkleRoot(_pId, _dealedEpoch, _merkleRoot);
        }
    }

    // ----- node claim --------------

    function claim(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount,
        bytes32[] calldata _merkleProof,
        ClaimType _claimType
    ) external onlyLatestContract(1, "stafiDistributor", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 &&
                getContractAddress(_pId, "projDistributor") == msg.sender,
            "Invalid caller"
        );
        uint256 claimableReward = _totalRewardAmount.sub(
            getTotalClaimedReward(_pId, _account)
        );
        uint256 claimableDeposit = _totalExitDepositAmount.sub(
            getTotalClaimedDeposit(_pId, _account)
        );

        // Verify the merkle proof.
        bytes32 node = keccak256(
            abi.encodePacked(
                _index,
                _account,
                _totalRewardAmount,
                _totalExitDepositAmount
            )
        );
        require(
            MerkleProof.verify(_merkleProof, getMerkleRoot(_pId), node),
            "invalid proof"
        );

        uint256 willClaimAmount;
        if (_claimType == ClaimType.CLAIMREWARD) {
            require(claimableReward > 0, "no claimable reward");

            setTotalClaimedReward(_pId, _account, _totalRewardAmount);
            willClaimAmount = claimableReward;
        } else if (_claimType == ClaimType.CLAIMDEPOSIT) {
            require(claimableDeposit > 0, "no claimable deposit");

            setTotalClaimedDeposit(_pId, _account, _totalExitDepositAmount);
            willClaimAmount = claimableDeposit;
        } else if (_claimType == ClaimType.CLAIMTOTAL) {
            willClaimAmount = claimableReward.add(claimableDeposit);
            require(willClaimAmount > 0, "no claimable amount");

            setTotalClaimedReward(_pId, _account, _totalRewardAmount);
            setTotalClaimedDeposit(_pId, _account, _totalExitDepositAmount);
        } else {
            revert("unknown claimType");
        }

        IProjDistributor projDistributor = IProjDistributor(msg.sender);
        projDistributor.claimToAccount(willClaimAmount, _account);

        emit Claimed(
            _index,
            _account,
            claimableReward,
            claimableDeposit,
            _claimType
        );
    }

    // --- helper ----

    function setTotalClaimedReward(
        uint256 _pId,
        address _account,
        uint256 _totalAmount
    ) internal {
        setUint(
            keccak256(
                abi.encodePacked(
                    "stafiDistributor.node.totalClaimedReward",
                    _pId,
                    _account
                )
            ),
            _totalAmount
        );
    }

    function setTotalClaimedDeposit(
        uint256 _pId,
        address _account,
        uint256 _totalAmount
    ) internal {
        setUint(
            keccak256(
                abi.encodePacked(
                    "stafiDistributor.node.totalClaimedDeposit",
                    _pId,
                    _account
                )
            ),
            _totalAmount
        );
    }

    function setMerkleDealedEpoch(uint256 _pId, uint256 _dealedEpoch) internal {
        setUint(
            keccak256(
                abi.encodePacked(
                    "stafiDistributor.merkleRoot.dealedEpoch",
                    _pId
                )
            ),
            _dealedEpoch
        );
    }

    function setMerkleRoot(uint256 _pId, bytes32 _merkleRoot) internal {
        setBytes32(
            keccak256(abi.encodePacked("stafiDistributor.merkleRoot", _pId)),
            _merkleRoot
        );
    }

    function setDistributeFeeDealedHeight(
        uint256 _pId,
        uint256 _dealedHeight
    ) internal {
        setUint(
            keccak256(
                abi.encodePacked(
                    "stafiDistributor.distributeFee.dealedHeight",
                    _pId
                )
            ),
            _dealedHeight
        );
    }

    function setDistributeSuperNodeFeeDealedHeight(
        uint256 _pId,
        uint256 _dealedHeight
    ) internal {
        setUint(
            keccak256(
                abi.encodePacked(
                    "stafiDistributor.distributeSuperNodeFee.dealedHeight",
                    _pId
                )
            ),
            _dealedHeight
        );
    }

    function setDistributeSlashDealedHeight(
        uint256 _pId,
        uint256 _dealedHeight
    ) internal {
        setUint(
            keccak256(
                abi.encodePacked(
                    "stafiDistributor.distributeSlashAmount.dealedHeight",
                    _pId
                )
            ),
            _dealedHeight
        );
    }

    function _voteProposal(
        uint256 _pId,
        address _voter,
        bytes32 _proposalId
    ) internal returns (bool) {
        // Get submission keys
        bytes32 proposalNodeKey = keccak256(
            abi.encodePacked(
                "stafiDistributor.proposal.node.key",
                _pId,
                _proposalId,
                _voter
            )
        );
        bytes32 proposalKey = keccak256(
            abi.encodePacked("stafiDistributor.proposal.key", _pId, _proposalId)
        );

        require(!getBool(proposalKey), "proposal already executed");

        // Check & update node submission status
        require(!getBool(proposalNodeKey), "duplicate vote");
        setBool(proposalNodeKey, true);

        // Increment submission count
        uint256 voteCount = getUint(proposalKey).add(1);
        setUint(proposalKey, voteCount);

        emit VoteProposal(_proposalId, _pId, _voter);

        // Check submission count & update network balances
        uint256 calcBase = 1 ether;

        uint256 threshold = ProjectSettings(_pId).getNodeConsensusThreshold();
        if (
            calcBase.mul(voteCount) >=
            ProjectNodeManager(_pId).getTrustedNodeCount().mul(threshold)
        ) {
            return true;
        }
        return false;
    }

    function _afterExecProposal(uint256 _pId, bytes32 _proposalId) internal {
        bytes32 proposalKey = keccak256(
            abi.encodePacked("stafiDistributor.proposal.key", _pId, _proposalId)
        );
        setBool(proposalKey, true);

        emit ProposalExecuted(_proposalId, _pId);
    }
}
