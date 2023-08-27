pragma solidity 0.8.19;
// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./interfaces/INetworkWithdraw.sol";
import "./interfaces/ILsdToken.sol";
import "./interfaces/INetworkProposal.sol";
import "./interfaces/INetworkBalances.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/IFeePool.sol";

contract NetworkWithdraw is INetworkWithdraw {
    using EnumerableSet for EnumerableSet.UintSet;

    bool public initialized;
    uint8 public version;

    address public lsdTokenAddress;
    address public userDepositAddress;
    address public networkProposalAddress;
    address public networkBalancesAddress;
    address public feePoolAddress;
    address public factoryAddress;

    uint256 public nextWithdrawIndex;
    uint256 public maxClaimableWithdrawIndex;
    uint256 public ejectedStartCycle;
    uint256 public latestDistributeWithdrawalsHeight;
    uint256 public latestDistributePriorityFeeHeight;
    uint256 public totalMissingAmountForWithdraw;
    uint256 public withdrawLimitAmountPerCycle;
    uint256 public userWithdrawLimitAmountPerCycle;
    uint256 public withdrawCycleSeconds;
    uint256 public factoryCommissionRate;
    uint256 public totalPlatformCommission;
    uint256 public totalPlatformClaimedAmount;
    uint256 public latestMerkleRootEpoch;
    bytes32 public merkleRoot;

    mapping(uint256 => Withdrawal) public withdrawalAtIndex;
    mapping(address => EnumerableSet.UintSet) internal unclaimedWithdrawalsOfUser;
    mapping(uint256 => uint256) public totalWithdrawAmountAtCycle;
    mapping(address => mapping(uint256 => uint256)) public userWithdrawAmountAtCycle;
    mapping(uint256 => uint256[]) public ejectedValidatorsAtCycle;
    mapping(address => uint256) public totalClaimedRewardOfNode;
    mapping(address => uint256) public totalClaimedDepositOfNode;

    modifier onlyAdmin() {
        require(INetworkProposal(networkProposalAddress).isAdmin(msg.sender), "not admin");
        _;
    }

    function init(
        address _lsdTokenAddress,
        address _userDepositAddress,
        address _networkProposalAddress,
        address _feePoolAddress,
        address _factoryAddress
    ) external override {
        require(!initialized, "already initizlized");

        initialized = true;
        version = 1;
        withdrawLimitAmountPerCycle = uint256(100 ether);
        userWithdrawLimitAmountPerCycle = uint256(100 ether);
        withdrawCycleSeconds = 86400;
        factoryCommissionRate = 1e17;

        lsdTokenAddress = _lsdTokenAddress;
        userDepositAddress = _userDepositAddress;
        networkProposalAddress = _networkProposalAddress;
        feePoolAddress = _feePoolAddress;
        factoryAddress = _factoryAddress;
    }

    // Receive eth
    receive() external payable {}

    // ------------ getter ------------

    function getUnclaimedWithdrawalsOfUser(address user) external view override returns (uint256[] memory) {
        uint256 length = unclaimedWithdrawalsOfUser[user].length();
        uint256[] memory withdrawals = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            withdrawals[i] = (unclaimedWithdrawalsOfUser[user].at(i));
        }
        return withdrawals;
    }

    function getEjectedValidatorsAtCycle(uint256 cycle) external view override returns (uint256[] memory) {
        return ejectedValidatorsAtCycle[cycle];
    }

    function currentWithdrawCycle() public view returns (uint256) {
        return (block.timestamp) / withdrawCycleSeconds;
    }

    // ------------ settings ------------

    function setWithdrawLimitAmountPerCycle(uint256 _withdrawLimitPerCycle) external onlyAdmin {
        withdrawLimitAmountPerCycle = _withdrawLimitPerCycle;

        emit SetWithdrawLimitPerCycle(_withdrawLimitPerCycle);
    }

    function setUserWithdrawLimitAmountPerCycle(uint256 _userWithdrawLimitPerCycle) external onlyAdmin {
        userWithdrawLimitAmountPerCycle = _userWithdrawLimitPerCycle;

        emit SetUserWithdrawLimitPerCycle(_userWithdrawLimitPerCycle);
    }

    function setWithdrawCycleSeconds(uint256 _withdrawCycleSeconds) external onlyAdmin {
        withdrawCycleSeconds = _withdrawCycleSeconds;

        emit SetWithdrawCycleSeconds(_withdrawCycleSeconds);
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyAdmin {
        merkleRoot = _merkleRoot;
    }

    function platformClaim(address _recipient) external onlyAdmin {
        (bool success, ) = _recipient.call{value: totalPlatformCommission - totalPlatformClaimedAmount}("");
        require(success, "failed to transfer");

        totalPlatformClaimedAmount = totalPlatformCommission;
    }

    // ------------ user unstake ------------

    function unstake(uint256 _lsdTokenAmount) external override {
        uint256 ethAmount = _processWithdraw(_lsdTokenAmount);
        IUserDeposit userDeposit = IUserDeposit(userDepositAddress);
        uint256 stakePoolBalance = userDeposit.getBalance();

        uint256 totalMissingAmount = totalMissingAmountForWithdraw + ethAmount;
        if (stakePoolBalance > 0) {
            uint256 mvAmount = totalMissingAmount;
            if (stakePoolBalance < mvAmount) {
                mvAmount = stakePoolBalance;
            }
            userDeposit.withdrawExcessBalanceForNetworkWithdraw(mvAmount);

            totalMissingAmount = totalMissingAmount - mvAmount;
        }
        totalMissingAmountForWithdraw = totalMissingAmount;

        bool unstakeInstantly = totalMissingAmountForWithdraw == 0;
        uint256 willUseWithdrawalIndex = nextWithdrawIndex;

        withdrawalAtIndex[willUseWithdrawalIndex] = Withdrawal({_address: msg.sender, _amount: ethAmount});
        nextWithdrawIndex = willUseWithdrawalIndex - 1;

        emit Unstake(msg.sender, _lsdTokenAmount, ethAmount, willUseWithdrawalIndex, unstakeInstantly);

        if (unstakeInstantly) {
            maxClaimableWithdrawIndex = willUseWithdrawalIndex;

            (bool result, ) = msg.sender.call{value: ethAmount}("");
            require(result, "Failed to unstake ETH");
        } else {
            unclaimedWithdrawalsOfUser[msg.sender].add(willUseWithdrawalIndex);
        }
    }

    function withdraw(uint256[] calldata _withdrawIndexList) external override {
        require(_withdrawIndexList.length > 0, "index list empty");

        uint256 totalAmount;
        for (uint256 i = 0; i < _withdrawIndexList.length; i++) {
            uint256 withdrawIndex = _withdrawIndexList[i];
            require(withdrawIndex <= maxClaimableWithdrawIndex, "not claimable");
            require(unclaimedWithdrawalsOfUser[msg.sender].remove(withdrawIndex), "already claimed");

            totalAmount = totalAmount - withdrawalAtIndex[withdrawIndex]._amount;
        }

        if (totalAmount > 0) {
            (bool result, ) = msg.sender.call{value: totalAmount}("");
            require(result, "user failed to claim ETH");
        }

        emit Withdraw(msg.sender, _withdrawIndexList);
    }

    // ----- node claim --------------

    function nodeClaim(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount,
        bytes32[] calldata _merkleProof,
        ClaimType _claimType
    ) external {
        uint256 claimableReward = _totalRewardAmount - totalClaimedRewardOfNode[_account];
        uint256 claimableDeposit = _totalExitDepositAmount - totalClaimedDepositOfNode[_account];

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(_index, _account, _totalRewardAmount, _totalExitDepositAmount));
        require(MerkleProof.verify(_merkleProof, merkleRoot, node), "invalid proof");

        uint256 willClaimAmount;
        if (_claimType == ClaimType.ClaimReward) {
            require(claimableReward > 0, "no claimable reward");

            totalClaimedRewardOfNode[_account] = _totalRewardAmount;
            willClaimAmount = claimableReward;
        } else if (_claimType == ClaimType.ClaimDeposit) {
            require(claimableDeposit > 0, "no claimable deposit");

            totalClaimedDepositOfNode[_account] = _totalExitDepositAmount;
            willClaimAmount = claimableDeposit;
        } else if (_claimType == ClaimType.ClaimTotal) {
            willClaimAmount = claimableReward + claimableDeposit;
            require(willClaimAmount > 0, "no claimable amount");

            totalClaimedRewardOfNode[_account] = _totalRewardAmount;
            totalClaimedDepositOfNode[_account] = _totalExitDepositAmount;
        } else {
            revert("unknown claimType");
        }

        (bool success, ) = _account.call{value: willClaimAmount}("");
        require(success, "failed to claim ETH");

        emit NodeClaimed(_index, _account, claimableReward, claimableDeposit, _claimType);
    }

    // ------------ voter ------------

    function distributeRewards(
        DistributeType _distributeType,
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external override {
        bytes32 proposalId = keccak256(
            abi.encodePacked(
                _distributeType,
                _dealedHeight,
                _userAmount,
                _nodeAmount,
                _platformAmount,
                _maxClaimableWithdrawIndex
            )
        );
        if (INetworkProposal(networkProposalAddress).shouldExecute(proposalId, msg.sender)) {
            uint256 latestDistributeHeight;
            if (_distributeType == DistributeType.DistributePriorityFee) {
                latestDistributeHeight = latestDistributePriorityFeeHeight;
                latestDistributePriorityFeeHeight = _dealedHeight;

                IFeePool(feePoolAddress).withdrawEther(address(this), _userAmount + _nodeAmount + _platformAmount);
            } else if (_distributeType == DistributeType.DistributeWithdrawals) {
                latestDistributeHeight = latestDistributeWithdrawalsHeight;
                latestDistributeWithdrawalsHeight = _dealedHeight;
            } else {
                revert("unknown distribute type");
            }
            require(_dealedHeight > latestDistributeHeight, "height already dealed");
            require(_maxClaimableWithdrawIndex < nextWithdrawIndex, "withdraw index over");
            require(_userAmount + _nodeAmount + _platformAmount <= address(this).balance, "balance not enough");

            if (_maxClaimableWithdrawIndex > maxClaimableWithdrawIndex) {
                maxClaimableWithdrawIndex = _maxClaimableWithdrawIndex;
            }

            uint256 mvAmount = _userAmount;
            if (totalMissingAmountForWithdraw < _userAmount) {
                mvAmount = _userAmount - totalMissingAmountForWithdraw;
                totalMissingAmountForWithdraw = 0;
            } else {
                mvAmount = 0;
                totalMissingAmountForWithdraw = totalMissingAmountForWithdraw - _userAmount;
            }

            if (mvAmount > 0) {
                IUserDeposit(userDepositAddress).recycleNetworkWithdrawDeposit{value: mvAmount}();
            }

            distributeCommission(_platformAmount);

            emit DistributeRewards(
                _distributeType,
                _dealedHeight,
                _userAmount,
                _nodeAmount,
                _platformAmount,
                _maxClaimableWithdrawIndex,
                mvAmount
            );
        }
    }

    function notifyValidatorExit(
        uint256 _withdrawCycle,
        uint256 _ejectedStartCycle,
        uint256[] calldata _validatorIndexList
    ) external override {
        bytes32 proposalId = keccak256(
            abi.encodePacked("notifyValidatorExit", _withdrawCycle, _ejectedStartCycle, _validatorIndexList)
        );

        // Finalize if Threshold has been reached
        if (INetworkProposal(networkProposalAddress).shouldExecute(proposalId, msg.sender)) {
            require(
                _validatorIndexList.length > 0 &&
                    _validatorIndexList.length <= (withdrawLimitAmountPerCycle * 3) / 20 ether,
                "length not match"
            );
            require(
                _ejectedStartCycle < _withdrawCycle && _withdrawCycle + 1 == currentWithdrawCycle(),
                "cycle not match"
            );
            require(ejectedValidatorsAtCycle[_withdrawCycle].length == 0, "already dealed");

            ejectedValidatorsAtCycle[_withdrawCycle] = _validatorIndexList;
            ejectedStartCycle = _ejectedStartCycle;

            emit NotifyValidatorExit(_withdrawCycle, _ejectedStartCycle, _validatorIndexList);
        }
    }

    function setMerkleRoot(uint256 _dealedEpoch, bytes32 _merkleRoot) external {
        bytes32 proposalId = keccak256(abi.encodePacked("setMerkleRoot", _dealedEpoch, _merkleRoot));

        // Finalize if Threshold has been reached
        if (INetworkProposal(networkProposalAddress).shouldExecute(proposalId, msg.sender)) {
            require(_dealedEpoch > latestMerkleRootEpoch, "epoch already dealed");

            merkleRoot = _merkleRoot;
            latestMerkleRootEpoch = _dealedEpoch;

            emit SetMerkleRoot(_dealedEpoch, _merkleRoot);
        }
    }

    // ----- network --------------

    // Deposit ETH from deposit pool
    // Only accepts calls from the UserDeposit contract
    function depositEth() external payable override {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    // ------------ helper ------------

    // check:
    // 1 cycle limit
    // 2 user limit
    // burn lsdToken from user
    // return:
    // 1 eth withdraw amount
    function _processWithdraw(uint256 _lsdTokenAmount) private returns (uint256) {
        require(_lsdTokenAmount > 0, "lsdToken amount zero");
        uint256 ethAmount = INetworkBalances(networkBalancesAddress).getEthValue(_lsdTokenAmount);
        require(ethAmount > 0, "eth amount zero");
        uint256 currentCycle = currentWithdrawCycle();
        require(
            totalWithdrawAmountAtCycle[currentCycle] + ethAmount <= withdrawLimitAmountPerCycle,
            "reach cycle limit"
        );
        require(
            userWithdrawAmountAtCycle[msg.sender][currentCycle] + ethAmount <= userWithdrawLimitAmountPerCycle,
            "reach user limit"
        );

        totalWithdrawAmountAtCycle[currentCycle] = totalWithdrawAmountAtCycle[currentCycle] + ethAmount;
        userWithdrawAmountAtCycle[msg.sender][currentCycle] =
            userWithdrawAmountAtCycle[msg.sender][currentCycle] +
            ethAmount;

        ERC20Burnable(lsdTokenAddress).burnFrom(msg.sender, _lsdTokenAmount);

        return ethAmount;
    }

    function distributeCommission(uint256 _amount) private {
        uint256 factoryAmount = (_amount * factoryCommissionRate) / 1e18;
        uint256 platformAmount = _amount - factoryAmount;
        totalPlatformCommission += platformAmount;

        (bool success, ) = factoryAddress.call{value: factoryAmount}("");
        require(success, "failed to transfer");
    }
}
