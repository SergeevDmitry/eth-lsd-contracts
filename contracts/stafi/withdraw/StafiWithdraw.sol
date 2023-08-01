pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../StafiBase.sol";
import "../interfaces/withdraw/IStafiWithdraw.sol";
import "../interfaces/storage/IStafiStorage.sol";
import "../../project/interfaces/IProjDistributor.sol";
import "../../project/interfaces/IProjNodeManager.sol";
import "../../project/interfaces/IProjRToken.sol";
import "../../project/interfaces/IProjSettings.sol";
import "../../project/interfaces/IProjUserDeposit.sol";
import "../../project/interfaces/IProjWithdraw.sol";

// Notice:
// 1 proxy admin must be different from owner
// 2 the new storage needs to be appended to the old storage if this contract is upgraded,
contract StafiWithdraw is StafiBase, IStafiWithdraw {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    struct Withdrawal {
        address _address;
        uint256 _amount;
    }

    mapping(uint256 => uint256) public nextWithdrawIndex;
    mapping(uint256 => uint256) public maxClaimableWithdrawIndex;
    mapping(uint256 => uint256) public ejectedStartCycle;
    mapping(uint256 => uint256) public latestDistributeHeight;
    mapping(uint256 => uint256) public totalMissingAmountForWithdraw;
    mapping(uint256 => uint256) public withdrawLimitPerCycle;
    mapping(uint256 => uint256) public userWithdrawLimitPerCycle;

    mapping(uint256 => mapping(uint256 => Withdrawal)) public withdrawalAtIndex;
    mapping(uint256 => mapping(address => EnumerableSet.UintSet))
        internal unclaimedWithdrawalsOfUser;
    mapping(uint256 => mapping(uint256 => uint256))
        public totalWithdrawAmountAtCycle;
    mapping(uint256 => mapping(address => mapping(uint256 => uint256)))
        public userWithdrawAmountAtCycle;
    mapping(uint256 => mapping(uint256 => uint256[]))
        public ejectedValidatorsAtCycle;

    // ------------ events ------------
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event Unstake(
        address indexed from,
        uint256 rethAmount,
        uint256 ethAmount,
        uint256 withdrawIndex,
        bool instantly
    );
    event Withdraw(address indexed from, uint256[] withdrawIndexList);
    event VoteProposal(bytes32 indexed proposalId, address voter, uint256 _pId);
    event ProposalExecuted(bytes32 indexed proposalId, uint256 _pId);
    event NotifyValidatorExit(
        uint256 pId,
        uint256 withdrawCycle,
        uint256 ejectedStartWithdrawCycle,
        uint256[] ejectedValidators
    );
    event DistributeWithdrawals(
        uint256 pId,
        uint256 dealedHeight,
        uint256 userAmount,
        uint256 nodeAmount,
        uint256 platformAmount,
        uint256 maxClaimableWithdrawIndex,
        uint256 mvAmount
    );
    event ReserveEthForWithdraw(
        uint256 pId,
        uint256 withdrawCycle,
        uint256 mvAmount
    );
    event SetWithdrawLimitPerCycle(uint256 withdrawLimitPerCycle);
    event SetUserWithdrawLimitPerCycle(uint256 userWithdrawLimitPerCycle);

    constructor() StafiBase(1, address(0)) {
        // By setting the version it is not possible to call setup anymore,
        // so we create a Safe with version 1.
        // This is an unusable Safe, perfect for the singleton
        version = 1;
    }

    function initialize(address _stafiStorageAddress) external {
        require(version == 0, "already initizlized");
        // init StafiBase storage
        version = 1;
        pId = 1;
        stafiStorage = IStafiStorage(_stafiStorageAddress);
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

    function ProjectUserDeposit(
        uint256 _pId
    ) private view returns (IProjUserDeposit) {
        return IProjUserDeposit(getContractAddress(_pId, "projUserDeposit"));
    }

    function ProjectDistributor(
        uint256 _pId
    ) private view returns (IProjDistributor) {
        return IProjDistributor(getContractAddress(_pId, "projDistributor"));
    }

    // ------------ getter ------------

    function getUnclaimedWithdrawalsOfUser(
        uint256 _pId,
        address user
    ) external view override returns (uint256[] memory) {
        uint256 length = unclaimedWithdrawalsOfUser[_pId][user].length();
        uint256[] memory withdrawals = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            withdrawals[i] = (unclaimedWithdrawalsOfUser[_pId][user].at(i));
        }
        return withdrawals;
    }

    function getEjectedValidatorsAtCycle(
        uint256 _pId,
        uint256 cycle
    ) external view override returns (uint256[] memory) {
        return ejectedValidatorsAtCycle[_pId][cycle];
    }

    function currentWithdrawCycle() public view returns (uint256) {
        return block.timestamp.sub(28800).div(86400);
    }

    // ------------ settings ------------

    function setWithdrawLimitPerCycle(
        uint256 _withdrawLimitPerCycle
    ) external onlySuperUser(1) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projWithdraw") == msg.sender,
            "Invalid caller"
        );
        withdrawLimitPerCycle[_pId] = _withdrawLimitPerCycle;

        emit SetWithdrawLimitPerCycle(_withdrawLimitPerCycle);
    }

    function setUserWithdrawLimitPerCycle(
        uint256 _userWithdrawLimitPerCycle
    ) external onlySuperUser(1) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projWithdraw") == msg.sender,
            "Invalid caller"
        );
        userWithdrawLimitPerCycle[_pId] = _userWithdrawLimitPerCycle;

        emit SetUserWithdrawLimitPerCycle(_userWithdrawLimitPerCycle);
    }

    // ------------ user unstake ------------

    function unstake(
        address _user,
        uint256 _rEthAmount
    ) external override onlyLatestContract(1, "stafiWithdraw", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projWithdraw") == msg.sender,
            "Invalid caller"
        );
        uint256 ethAmount = _processWithdraw(_pId, _user, _rEthAmount);
        IProjUserDeposit projUserDeposit = IProjUserDeposit(
            getContractAddress(_pId, "projUserDeposit")
        );
        uint256 stakePoolBalance = projUserDeposit.getBalance();

        uint256 totalMissingAmount = totalMissingAmountForWithdraw[_pId].add(
            ethAmount
        );
        if (stakePoolBalance > 0) {
            uint256 mvAmount = totalMissingAmount;
            if (stakePoolBalance < mvAmount) {
                mvAmount = stakePoolBalance;
            }
            projUserDeposit.withdrawExcessBalanceForWithdraw(mvAmount);

            totalMissingAmount = totalMissingAmount.sub(mvAmount);
        }
        totalMissingAmountForWithdraw[_pId] = totalMissingAmount;

        bool unstakeInstantly = totalMissingAmountForWithdraw[_pId] == 0;
        uint256 willUseWithdrawalIndex = nextWithdrawIndex[_pId];

        withdrawalAtIndex[_pId][willUseWithdrawalIndex] = Withdrawal({
            _address: _user,
            _amount: ethAmount
        });
        nextWithdrawIndex[_pId] = willUseWithdrawalIndex.add(1);

        emit Unstake(
            _user,
            _rEthAmount,
            ethAmount,
            willUseWithdrawalIndex,
            unstakeInstantly
        );

        if (unstakeInstantly) {
            maxClaimableWithdrawIndex[_pId] = willUseWithdrawalIndex;
            IProjWithdraw projWithdraw = IProjWithdraw(msg.sender);
            projWithdraw.doWithdraw(_user, ethAmount);
        } else {
            unclaimedWithdrawalsOfUser[_pId][_user].add(willUseWithdrawalIndex);
        }
    }

    function withdraw(
        address _user,
        uint256[] calldata _withdrawIndexList
    ) external override onlyLatestContract(1, "stafiWithdraw", address(this)) {
        require(_withdrawIndexList.length > 0, "index list empty");

        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projWithdraw") == msg.sender,
            "Invalid caller"
        );

        uint256 totalAmount;
        for (uint256 i = 0; i < _withdrawIndexList.length; i++) {
            uint256 withdrawIndex = _withdrawIndexList[i];
            require(
                withdrawIndex <= maxClaimableWithdrawIndex[_pId],
                "not claimable"
            );
            require(
                unclaimedWithdrawalsOfUser[_pId][_user].remove(withdrawIndex),
                "already claimed"
            );

            totalAmount = totalAmount.add(
                withdrawalAtIndex[_pId][withdrawIndex]._amount
            );
        }

        if (totalAmount > 0) {
            IProjWithdraw projWithdraw = IProjWithdraw(msg.sender);
            projWithdraw.doWithdraw(_user, totalAmount);
        }

        emit Withdraw(_user, _withdrawIndexList);
    }

    // ------------ voter(trust node) ------------

    function distributeWithdrawals(
        address _voter,
        uint256 _dealedHeight,
        uint256 _userAmount,
        uint256 _nodeAmount,
        uint256 _platformAmount,
        uint256 _maxClaimableWithdrawIndex
    ) external override onlyLatestContract(1, "stafiWithdraw", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projWithdraw") == msg.sender,
            "Invalid caller"
        );

        require(
            _dealedHeight > latestDistributeHeight[_pId],
            "height already dealed"
        );
        require(
            _maxClaimableWithdrawIndex < nextWithdrawIndex[_pId],
            "withdraw index over"
        );
        require(
            _userAmount.add(_nodeAmount).add(_platformAmount) <=
                address(msg.sender).balance,
            "balance not enough"
        );

        bytes32 proposalId = keccak256(
            abi.encodePacked(
                "distributeWithdrawals",
                _pId,
                _dealedHeight,
                _userAmount,
                _nodeAmount,
                _platformAmount,
                _maxClaimableWithdrawIndex
            )
        );
        bool needExe = _voteProposal(_pId, _voter, proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            if (_maxClaimableWithdrawIndex > maxClaimableWithdrawIndex[_pId]) {
                maxClaimableWithdrawIndex[_pId] = _maxClaimableWithdrawIndex;
            }

            latestDistributeHeight[_pId] = _dealedHeight;

            uint256 mvAmount = _userAmount;
            if (totalMissingAmountForWithdraw[_pId] < _userAmount) {
                mvAmount = _userAmount.sub(totalMissingAmountForWithdraw[_pId]);
                totalMissingAmountForWithdraw[_pId] = 0;
            } else {
                mvAmount = 0;
                totalMissingAmountForWithdraw[
                    _pId
                ] = totalMissingAmountForWithdraw[_pId].sub(_userAmount);
            }

            if (mvAmount > 0) {
                IProjWithdraw(msg.sender).recycleUserDeposit(mvAmount);
            }

            // distribute withdrawals
            uint256 nodeAndPlatformAmount = _nodeAmount.add(_platformAmount);
            if (nodeAndPlatformAmount > 0) {
                IProjWithdraw(msg.sender).doDistributeWithdrawals(
                    nodeAndPlatformAmount
                );
            }

            _afterExecProposal(_pId, proposalId);

            emit DistributeWithdrawals(
                _pId,
                _dealedHeight,
                _userAmount,
                _nodeAmount,
                _platformAmount,
                _maxClaimableWithdrawIndex,
                mvAmount
            );
        }
    }

    function reserveEthForWithdraw(
        address _voter,
        uint256 _withdrawCycle
    ) external override onlyLatestContract(1, "stafiWithdraw", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projWithdraw") == msg.sender,
            "Invalid caller"
        );

        bytes32 proposalId = keccak256(
            abi.encodePacked("reserveEthForWithdraw", _pId, _withdrawCycle)
        );
        bool needExe = _voteProposal(_pId, _voter, proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            IProjUserDeposit projUserDeposit = ProjectUserDeposit(_pId);
            uint256 depositPoolBalance = projUserDeposit.getBalance();

            if (
                depositPoolBalance > 0 &&
                totalMissingAmountForWithdraw[_pId] > 0
            ) {
                uint256 mvAmount = totalMissingAmountForWithdraw[_pId];
                if (depositPoolBalance < mvAmount) {
                    mvAmount = depositPoolBalance;
                }
                projUserDeposit.withdrawExcessBalanceForWithdraw(mvAmount);

                totalMissingAmountForWithdraw[
                    _pId
                ] = totalMissingAmountForWithdraw[_pId].sub(mvAmount);

                emit ReserveEthForWithdraw(_pId, _withdrawCycle, mvAmount);
            }
            _afterExecProposal(_pId, proposalId);
        }
    }

    function notifyValidatorExit(
        address _voter,
        uint256 _withdrawCycle,
        uint256 _ejectedStartCycle,
        uint256[] calldata _validatorIndexList
    ) external override onlyLatestContract(1, "stafiWithdraw", address(this)) {
        uint256 _pId = getProjectId(msg.sender);
        require(
            _pId > 1 && getContractAddress(_pId, "projWithdraw") == msg.sender,
            "Invalid caller"
        );
        require(
            _validatorIndexList.length > 0 &&
                _validatorIndexList.length <=
                withdrawLimitPerCycle[_pId].mul(3).div(20 ether),
            "length not match"
        );
        require(
            _ejectedStartCycle < _withdrawCycle &&
                _withdrawCycle.add(1) == currentWithdrawCycle(),
            "cycle not match"
        );
        require(
            ejectedValidatorsAtCycle[_pId][_withdrawCycle].length == 0,
            "already dealed"
        );

        bytes32 proposalId = keccak256(
            abi.encodePacked(
                "notifyValidatorExit",
                _pId,
                _withdrawCycle,
                _ejectedStartCycle,
                _validatorIndexList
            )
        );
        bool needExe = _voteProposal(_pId, _voter, proposalId);

        // Finalize if Threshold has been reached
        if (needExe) {
            ejectedValidatorsAtCycle[_pId][
                _withdrawCycle
            ] = _validatorIndexList;
            ejectedStartCycle[_pId] = _ejectedStartCycle;

            emit NotifyValidatorExit(
                _pId,
                _withdrawCycle,
                _ejectedStartCycle,
                _validatorIndexList
            );

            _afterExecProposal(_pId, proposalId);
        }
    }

    // ------------ helper ------------

    // check:
    // 1 cycle limit
    // 2 user limit
    // burn reth from user
    // return:
    // 1 eth withdraw amount
    function _processWithdraw(
        uint256 _pId,
        address _user,
        uint256 _rEthAmount
    ) private returns (uint256) {
        require(_rEthAmount > 0, "reth amount zero");
        address rEthAddress = getContractAddress(_pId, "projRToken");
        uint256 ethAmount = IProjRToken(rEthAddress).getEthValue(_rEthAmount);
        require(ethAmount > 0, "eth amount zero");
        uint256 currentCycle = currentWithdrawCycle();
        require(
            totalWithdrawAmountAtCycle[_pId][currentCycle].add(ethAmount) <=
                withdrawLimitPerCycle[_pId],
            "reach cycle limit"
        );
        require(
            userWithdrawAmountAtCycle[_pId][_user][currentCycle].add(
                ethAmount
            ) <= userWithdrawLimitPerCycle[_pId],
            "reach user limit"
        );

        totalWithdrawAmountAtCycle[_pId][
            currentCycle
        ] = totalWithdrawAmountAtCycle[_pId][currentCycle].add(ethAmount);
        userWithdrawAmountAtCycle[_pId][_user][
            currentCycle
        ] = userWithdrawAmountAtCycle[_pId][_user][currentCycle].add(ethAmount);

        ERC20Burnable(rEthAddress).burnFrom(_user, _rEthAmount);

        return ethAmount;
    }

    function _voteProposal(
        uint256 _pId,
        address _voter,
        bytes32 _proposalId
    ) internal returns (bool) {
        // Get submission keys
        bytes32 proposalNodeKey = keccak256(
            abi.encodePacked(
                "stafiWithdraw.proposal.node.key",
                _pId,
                _proposalId,
                _voter
            )
        );
        bytes32 proposalKey = keccak256(
            abi.encodePacked("stafiWithdraw.proposal.key", _pId, _proposalId)
        );

        require(!getBool(proposalKey), "proposal already executed");

        // Check & update node submission status
        require(!getBool(proposalNodeKey), "duplicate vote");
        setBool(proposalNodeKey, true);

        // Increment submission count
        uint256 voteCount = getUint(proposalKey).add(1);
        setUint(proposalKey, voteCount);

        emit VoteProposal(_proposalId, _voter, _pId);

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
            abi.encodePacked("stafiWithdraw.proposal.key", _pId, _proposalId)
        );
        setBool(proposalKey, true);

        emit ProposalExecuted(_proposalId, _pId);
    }
}
