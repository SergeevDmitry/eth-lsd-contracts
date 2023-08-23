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
    address public networkProposalAddress;
    address public feePoolAddress;
    address public userDepositAddress;

    uint256 public merkleDealedEpoch;
    mapping(address => uint256) public totalClaimedRewardOf;
    mapping(address => uint256) public totalClaimedDepositOf;
    bytes32 public merkleRoot;
    uint256 public distributeLightNodeFeeDealedHeight;
    uint256 public distributeSuperNodeFeeDealedHeight;
    uint256 public distributeSlashDealedHeight;

    event Claimed(
        uint256 index,
        address account,
        uint256 claimableReward,
        uint256 claimableDeposit,
        ClaimType claimType
    );

    event DistributeFee(uint256 dealedHeight, uint256 userAmount, uint256 nodeAmount, uint256 platformAmount);
    event DistributeSuperNodeFee(uint256 dealedHeight, uint256 userAmount, uint256 nodeAmount, uint256 platformAmount);
    event DistributeSlash(uint256 dealedHeight, uint256 slashAmount);
    event SetMerkleRoot(uint256 dealedEpoch, bytes32 merkleRoot);

    enum ClaimType {
        None,
        CLAIMREWARD,
        CLAIMDEPOSIT,
        CLAIMTOTAL
    }

    receive() external payable {}

    // distribute withdrawals for node/platform, accept calls from userWithdraw
    function distributeWithdrawals() external payable override {
        require(msg.value > 0, "zero amount");
    }

    // ------------ getter ------------

    function getMerkleDealedEpoch() public view returns (uint256) {
        return merkleDealedEpoch;
    }

    function getTotalClaimedReward(address _account) public view returns (uint256) {
        return totalClaimedRewardOf[_account];
    }

    function getTotalClaimedDeposit(address _account) public view returns (uint256) {
        return totalClaimedDepositOf[_account];
    }

    function getMerkleRoot() public view returns (bytes32) {
        return merkleRoot;
    }

    function getDistributeLightNodeFeeDealedHeight() public view returns (uint256) {
        return distributeLightNodeFeeDealedHeight;
    }

    function getDistributeSuperNodeFeeDealedHeight() public view returns (uint256) {
        return distributeSuperNodeFeeDealedHeight;
    }

    function getDistributeSlashDealedHeight() public view returns (uint256) {
        return distributeSlashDealedHeight;
    }

    // ------------ settings ------------

    function updateMerkleRoot(bytes32 _merkleRoot) external {
        require(INetworkProposal(networkProposalAddress).isAdmin(msg.sender), "not admin");

        merkleRoot = _merkleRoot;
    }

    // ------------ vote ------------

    // v1: platform = 10% node = 90%*(nodedeposit/32)+90%*(1- nodedeposit/32)*10%  user = 90%*(1- nodedeposit/32)*90%
    // v2: platform = 5%  node = 5% + (90% * nodedeposit/32) user = 90%*(1-nodedeposit/32)
    // distribute fee of feePool for user/node/platform
    function distributeLightNodeFee(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount
    ) external {
        INetworkProposal networkProposal = INetworkProposal(networkProposalAddress);
        require(networkProposal.isVoter(msg.sender), "not voter");

        uint256 totalAmount = _userAmount + _nodeAmount + _platformAmount;
        require(totalAmount > 0, "zero amount");

        require(_dealedHeight > distributeLightNodeFeeDealedHeight, "height already dealed");

        bytes32 proposalId = keccak256(
            abi.encodePacked("distributeLightNodeFee", _dealedHeight, _userAmount, _nodeAmount, _platformAmount)
        );

        (Proposal memory proposal, uint8 threshold) = networkProposal.checkProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            IFeePool feePool = IFeePool(feePoolAddress);
            IUserDeposit userDeposit = IUserDeposit(userDepositAddress);

            feePool.withdrawEther(address(this), totalAmount);

            if (_userAmount > 0) {
                userDeposit.recycleDistributorDeposit{value: _userAmount}();
            }

            distributeLightNodeFeeDealedHeight = _dealedHeight;

            emit DistributeFee(_dealedHeight, _userAmount, _nodeAmount, _platformAmount);
        }
        networkProposal.saveProposal(proposalId, proposal);
    }

    // v1: platform = 10% node = 9%  user = 81%
    // v2: platform = 5%  node = 5%  user = 90%
    // distribute fee of superNode feePool for user/node/platform
    function distributeSuperNodeFee(
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount
    ) external {
        INetworkProposal networkProposal = INetworkProposal(networkProposalAddress);
        require(networkProposal.isVoter(msg.sender), "not voter");

        uint256 totalAmount = _userAmount + _nodeAmount + _platformAmount;
        require(totalAmount > 0, "zero amount");

        require(_dealedHeight > getDistributeSuperNodeFeeDealedHeight(), "height already dealed");

        bytes32 proposalId = keccak256(
            abi.encodePacked("distributeSuperNodeFee", _dealedHeight, _userAmount, _nodeAmount, _platformAmount)
        );

        (Proposal memory proposal, uint8 threshold) = networkProposal.checkProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            IFeePool feePool = IFeePool(feePoolAddress);
            IUserDeposit userDeposit = IUserDeposit(userDepositAddress);

            feePool.withdrawEther(address(this), totalAmount);

            if (_userAmount > 0) {
                userDeposit.recycleDistributorDeposit{value: _userAmount}();
            }

            distributeSuperNodeFeeDealedHeight = _dealedHeight;

            emit DistributeSuperNodeFee(_dealedHeight, _userAmount, _nodeAmount, _platformAmount);
        }

        networkProposal.saveProposal(proposalId, proposal);
    }

    // distribute slash amount for user
    function distributeSlashAmount(uint256 _dealedHeight, uint256 _amount) external {
        INetworkProposal networkProposal = INetworkProposal(networkProposalAddress);
        require(networkProposal.isVoter(msg.sender), "not voter");

        require(_amount > 0, "zero amount");

        require(_dealedHeight > getDistributeSlashDealedHeight(), "height already dealed");

        bytes32 proposalId = keccak256(abi.encodePacked("distributeSlashAmount", _dealedHeight, _amount));

        (Proposal memory proposal, uint8 threshold) = networkProposal.checkProposal(proposalId);

        // Finalize if Threshold has been reached
        if (proposal._yesVotesTotal >= threshold) {
            IUserDeposit stafiUserDeposit = IUserDeposit(userDepositAddress);

            stafiUserDeposit.recycleDistributorDeposit{value: _amount}();

            distributeSlashDealedHeight = _dealedHeight;

            emit DistributeSlash(_dealedHeight, _amount);
        }
        networkProposal.saveProposal(proposalId, proposal);
    }

    function setMerkleRoot(uint256 _dealedEpoch, bytes32 _merkleRoot) external {
        INetworkProposal networkProposal = INetworkProposal(networkProposalAddress);
        require(networkProposal.isVoter(msg.sender), "not voter");

        uint256 predealedEpoch = getMerkleDealedEpoch();
        require(_dealedEpoch > predealedEpoch, "epoch already dealed");

        bytes32 proposalId = keccak256(abi.encodePacked("setMerkleRoot", _dealedEpoch, _merkleRoot));
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
        uint256 claimableReward = _totalRewardAmount - getTotalClaimedReward(_account);
        uint256 claimableDeposit = _totalExitDepositAmount - getTotalClaimedDeposit(_account);

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _totalRewardAmount, _totalExitDepositAmount));
        require(MerkleProof.verify(_merkleProof, getMerkleRoot(), node), "invalid proof");

        uint256 willClaimAmount;
        if (_claimType == ClaimType.CLAIMREWARD) {
            require(claimableReward > 0, "no claimable reward");

            totalClaimedRewardOf[_account] = _totalRewardAmount;
            willClaimAmount = claimableReward;
        } else if (_claimType == ClaimType.CLAIMDEPOSIT) {
            require(claimableDeposit > 0, "no claimable deposit");

            totalClaimedDepositOf[_account] = _totalExitDepositAmount;
            willClaimAmount = claimableDeposit;
        } else if (_claimType == ClaimType.CLAIMTOTAL) {
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
}
