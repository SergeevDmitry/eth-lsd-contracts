pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/IDistributor.sol";
import "./interfaces/INetworkProposal.sol";
import "./interfaces/IProposalType.sol";

// Distribute network validator priorityFees/withdrawals/slashs
contract Distributor is IDistributor, IProposalType {
    bool public initialized;
    uint8 public version;

    address public networkProposalAddress;
    address public feePoolAddress;
    address public userDepositAddress;

    uint256 public merkleDealedEpoch;
    uint256 public distributePriorityFeeDealedHeight;

    bytes32 public merkleRoot;

    mapping(address => uint256) public totalClaimedRewardOf;
    mapping(address => uint256) public totalClaimedDepositOf;

    modifier onlyVoter() {
        require(INetworkProposal(networkProposalAddress).isVoter(msg.sender), "not voter");
        _;
    }

    modifier onlyAdmin() {
        require(INetworkProposal(networkProposalAddress).isAdmin(msg.sender), "not admin");
        _;
    }

    function init(
        address _networkProposalAddress,
        address _feePoolAddress,
        address _userDepositAddress
    ) external override {
        require(!initialized, "already initizlized");

        initialized = true;
        version = 1;
        networkProposalAddress = _networkProposalAddress;
        feePoolAddress = _feePoolAddress;
        userDepositAddress = _userDepositAddress;
    }

    receive() external payable {}

    // ------------ settings ------------

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        merkleRoot = _merkleRoot;
    }

    // ------------ vote ------------

    // lightNode: platform = 5%  node = 5% + (90% * nodedeposit/32) user = 90%*(1-nodedeposit/32)
    // superNode: platform = 5%  node = 5%  user = 90%
    // distribute priority fee of feePool for user/node/platform
    function distributePriorityFee(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount
    ) external onlyVoter {
        uint256 totalAmount = _userAmount + _nodeAmount + _platformAmount;
        require(totalAmount > 0, "zero amount");

        require(_dealedHeight > distributePriorityFeeDealedHeight, "height already dealed");

        bytes32 proposalId = keccak256(
            abi.encodePacked("distributeLightNodeFee", _dealedHeight, _userAmount, _nodeAmount, _platformAmount)
        );

        INetworkProposal networkProposal = INetworkProposal(networkProposalAddress);
        (Proposal memory proposal, uint8 threshold) = networkProposal.checkProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            IFeePool feePool = IFeePool(feePoolAddress);
            IUserDeposit userDeposit = IUserDeposit(userDepositAddress);

            feePool.withdrawEther(address(this), totalAmount);

            if (_userAmount > 0) {
                userDeposit.recycleDistributorDeposit{value: _userAmount}();
            }

            distributePriorityFeeDealedHeight = _dealedHeight;

            emit DistributeFee(_dealedHeight, _userAmount, _nodeAmount, _platformAmount);
        }
        networkProposal.saveProposal(proposalId, proposal);
    }

    function setMerkleRoot(uint256 _dealedEpoch, bytes32 _merkleRoot) external onlyVoter {
        require(_dealedEpoch > merkleDealedEpoch, "epoch already dealed");

        bytes32 proposalId = keccak256(abi.encodePacked("setMerkleRoot", _dealedEpoch, _merkleRoot));

        INetworkProposal networkProposal = INetworkProposal(networkProposalAddress);
        (Proposal memory proposal, uint8 threshold) = networkProposal.checkProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            merkleRoot = _merkleRoot;
            merkleDealedEpoch = _dealedEpoch;

            emit SetMerkleRoot(_dealedEpoch, _merkleRoot);
        }
        networkProposal.saveProposal(proposalId, proposal);
    }

    // ----- node claim --------------

    function claim(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount,
        bytes32[] calldata _merkleProof,
        ClaimType _claimType
    ) external {
        uint256 claimableReward = _totalRewardAmount - totalClaimedRewardOf[_account];
        uint256 claimableDeposit = _totalExitDepositAmount - totalClaimedDepositOf[_account];

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _totalRewardAmount, _totalExitDepositAmount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "invalid proof");

        uint256 willClaimAmount;
        if (_claimType == ClaimType.ClaimReward) {
            require(claimableReward > 0, "no claimable reward");

            totalClaimedRewardOf[_account] = _totalRewardAmount;
            willClaimAmount = claimableReward;
        } else if (_claimType == ClaimType.ClaimDeposit) {
            require(claimableDeposit > 0, "no claimable deposit");

            totalClaimedDepositOf[_account] = _totalExitDepositAmount;
            willClaimAmount = claimableDeposit;
        } else if (_claimType == ClaimType.ClaimTotal) {
            willClaimAmount = claimableReward + claimableDeposit;
            require(willClaimAmount > 0, "no claimable amount");

            totalClaimedRewardOf[_account] = _totalRewardAmount;
            totalClaimedDepositOf[_account] = _totalExitDepositAmount;
        } else {
            revert("unknown claimType");
        }

        (bool success, ) = _account.call{value: willClaimAmount}("");
        require(success, "failed to claim ETH");

        emit Claimed(_index, _account, claimableReward, claimableDeposit, _claimType);
    }

    // ----- network --------------

    // distribute withdrawals for node/platform, accept calls from userWithdraw
    function distributeWithdrawals() external payable override {
        require(msg.value > 0, "zero amount");
    }
}
