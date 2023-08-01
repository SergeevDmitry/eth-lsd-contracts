pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../stafi/StafiBase.sol";
import "../stafi/interfaces/reward/IStafiDistributor.sol";
import "../stafi/types/ClaimType.sol";
import "./interfaces/IProjEther.sol";
import "./interfaces/IProjDistributor.sol";

contract ProjDistributor is StafiBase, IProjDistributor {
    // Libs
    using SafeMath for uint256;

    event Claimed(
        uint256 index,
        address account,
        uint256 claimableReward,
        uint256 claimableDeposit,
        ClaimType claimType
    );
    event DistributeFee(uint256 dealedHeight, uint256 totalAmount);
    event DistributeSuperNodeFee(uint256 dealedHeight, uint256 totalAmount);
    event DistributeSlash(uint256 dealedHeight, uint256 slashAmount);
    event SetMerkleRoot(uint256 dealedEpoch, bytes32 merkleRoot);

    // Construct
    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        // Version
        version = 1;
    }

    receive() external payable {}

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal()
        external
        payable
        override
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyLatestContract(pId, "projEther", msg.sender)
    {}

    // distribute withdrawals for node/platform, accept calls from stafiWithdraw
    function distributeWithdrawals(
        uint256 _value
    )
        external
        override
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyLatestContract(pId, "stafiDistributor", msg.sender)
    {
        require(_value > 0, "zero amount");

        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.depositEther{value: _value}();
    }

    // ------------ settings ---------

    function updateMerkleRoot(
        bytes32 _merkleRoot
    )
        external
        onlyLatestContract(pId, "projDistributor", address(this))
        onlySuperNode(pId, msg.sender)
    {
        IStafiDistributor stafiDistributor = IStafiDistributor(
            getContractAddress(1, "stafiDistributor")
        );
        stafiDistributor.updateMerkleRoot(_merkleRoot);
    }

    // ------------ vote ------------

    // v2: platform = 5%  node = 5% + (90% * nodedeposit/32) user = 90%*(1-nodedeposit/32)
    // distribute fee of feePool for user/node/platform
    function distributeFee(
        uint256 _dealedHeight,
        uint256 _totalAmount
    )
        external
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyTrustedNode(pId, msg.sender)
    {
        IStafiDistributor stafiDistributor = IStafiDistributor(
            getContractAddress(1, "stafiDistributor")
        );
        stafiDistributor.distributeFee(msg.sender, _dealedHeight, _totalAmount);
        emit DistributeFee(_dealedHeight, _totalAmount);
    }

    function distributeSuperNodeFee(
        uint256 _dealedHeight,
        uint256 _totalAmount
    )
        external
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyTrustedNode(pId, msg.sender)
    {
        IStafiDistributor stafiDistributor = IStafiDistributor(
            getContractAddress(1, "stafiDistributor")
        );
        stafiDistributor.distributeSuperNodeFee(
            msg.sender,
            _dealedHeight,
            _totalAmount
        );
        emit DistributeSuperNodeFee(_dealedHeight, _totalAmount);
    }

    function distributeSlashAmount(
        uint256 _dealedHeight,
        uint256 _amount
    )
        external
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyTrustedNode(pId, msg.sender)
    {
        IStafiDistributor stafiDistributor = IStafiDistributor(
            getContractAddress(1, "stafiDistributor")
        );
        stafiDistributor.distributeSlashAmount(
            msg.sender,
            _dealedHeight,
            _amount
        );
        emit DistributeSlash(_dealedHeight, _amount);
    }

    function setMerkleRoot(
        uint256 _dealedEpoch,
        bytes32 _merkleRoot
    )
        external
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyTrustedNode(pId, msg.sender)
    {
        IStafiDistributor stafiDistributor = IStafiDistributor(
            getContractAddress(1, "stafiDistributor")
        );
        stafiDistributor.setMerkleRoot(msg.sender, _dealedEpoch, _merkleRoot);
        emit SetMerkleRoot(_dealedEpoch, _merkleRoot);
    }

    function claim(
        uint256 _index,
        address _account,
        uint256 _totalRewardAmount,
        uint256 _totalExitDepositAmount,
        bytes32[] calldata _merkleProof,
        ClaimType _claimType
    ) external onlyLatestContract(pId, "projDistributor", address(this)) {
        IStafiDistributor stafiDistributor = IStafiDistributor(
            getContractAddress(1, "stafiDistributor")
        );
        stafiDistributor.claim(
            _index,
            _account,
            _totalRewardAmount,
            _totalExitDepositAmount,
            _merkleProof,
            _claimType
        );
    }

    function claimToAccount(
        uint256 _value,
        address _account
    )
        external
        override
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyLatestContract(1, "stafiDistributor", msg.sender)
    {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.withdrawEther(_value);
        (bool success, ) = _account.call{value: _value}("");
        require(success, "failed to claim ETH");
    }
}
