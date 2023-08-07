pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../stafi/StafiBase.sol";
import "../stafi/interfaces/node/IStafiLightNode.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IProjEther.sol";
import "./interfaces/IProjEtherWithdrawer.sol";
import "./interfaces/IProjLightNode.sol";
import "./interfaces/IProjSettings.sol";

contract ProjLightNode is StafiBase, IProjLightNode, IProjEtherWithdrawer {
    // Libs
    using SafeMath for uint256;

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event SetPubkeyStatus(bytes pubkey, uint256 status);
    event Deposited(address node, bytes pubkey, bytes validatorSignature, uint256 amount);
    event Staked(address node, bytes pubkey);

    constructor(uint256 _pId, address _stafiStorageAddress) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
    }

    // Receive a ether withdrawal
    // Only accepts calls from the StafiEther contract
    function receiveEtherWithdrawal()
        external
        payable
        override
        onlyLatestContract(pId, "projDistributor", address(this))
        onlyLatestContract(pId, "projEther", msg.sender)
    {}

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth() external payable override onlyLatestContract(pId, "projUserDeposit", msg.sender) {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function EthDeposit() private view returns (IDepositContract) {
        return IDepositContract(getContractAddress(1, "ethDeposit"));
    }

    function ProjSettings() private view returns (IProjSettings) {
        return IProjSettings(getContractAddress(pId, "projSettings"));
    }

    function deposit(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external payable onlyLatestContract(pId, "projLightNode", address(this)) {
        IStafiLightNode stafiLightNode = IStafiLightNode(getContractAddress(1, "stafiLightNode"));
        stafiLightNode.deposit(msg.sender, msg.value, _validatorPubkeys, _validatorSignatures, _depositDataRoots);
    }

    function ethDeposit(
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    )
        external
        onlyLatestContract(pId, "projLightNode", address(this))
        onlyLatestContract(1, "stafiLightNode", msg.sender)
    {
        uint256 depositAmount = ProjSettings().getCurrentNodeDepositAmount();
        // Send staking deposit to casper
        EthDeposit().deposit{value: depositAmount}(
            _validatorPubkey,
            ProjSettings().getWithdrawalCredentials(),
            _validatorSignature,
            _depositDataRoot
        );
        emit Deposited(_user, _validatorPubkey, _validatorSignature, depositAmount);
    }

    function stake(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external payable onlyLatestContract(pId, "projLightNode", address(this)) {
        IStafiLightNode stafiLightNode = IStafiLightNode(getContractAddress(1, "stafiLightNode"));
        stafiLightNode.stake(msg.sender, _validatorPubkeys, _validatorSignatures, _depositDataRoots);
    }

    function ethStake(
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    )
        external
        onlyLatestContract(pId, "projLightNode", address(this))
        onlyLatestContract(1, "stafiLightNode", msg.sender)
    {
        uint256 stakeAmount = uint256(32 ether).sub(ProjSettings().getCurrentNodeDepositAmount());
        // Send staking deposit to casper
        EthDeposit().deposit{value: stakeAmount}(
            _validatorPubkey,
            ProjSettings().getWithdrawalCredentials(),
            _validatorSignature,
            _depositDataRoot
        );
        emit Staked(_user, _validatorPubkey);
    }

    function offBoard(
        bytes calldata _validatorPubkey
    ) external onlyLatestContract(pId, "projLightNode", address(this)) {
        IStafiLightNode stafiLightNode = IStafiLightNode(getContractAddress(1, "stafiLightNode"));
        stafiLightNode.offBoard(msg.sender, _validatorPubkey);
    }

    function provideNodeDepositToken(
        bytes calldata _validatorPubkey
    ) external payable onlyLatestContract(pId, "projLightNode", address(this)) {
        IStafiLightNode stafiLightNode = IStafiLightNode(getContractAddress(1, "stafiLightNode"));
        stafiLightNode.provideNodeDepositToken(msg.value, _validatorPubkey);
    }

    function withdrawNodeDepositToken(
        bytes calldata _validatorPubkey
    ) external onlyLatestContract(pId, "projLightNode", address(this)) {
        IStafiLightNode stafiLightNode = IStafiLightNode(getContractAddress(1, "stafiLightNode"));
        stafiLightNode.withdrawNodeDepositToken(msg.sender, _validatorPubkey);
    }

    function voteWithdrawCredentials(
        bytes[] calldata _pubkeys,
        bool[] calldata _matchs
    ) external onlyLatestContract(pId, "projLightNode", address(this)) {
        IStafiLightNode stafiLightNode = IStafiLightNode(getContractAddress(1, "stafiLightNode"));
        stafiLightNode.voteWithdrawCredentials(msg.sender, _pubkeys, _matchs);
    }

    function provideEther(
        uint256 _value
    )
        external
        onlyLatestContract(pId, "projLightNode", address(this))
        onlyLatestContract(1, "stafiLightNode", msg.sender)
    {
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.depositEther{value: _value}();
    }

    function withdrawEther(
        address _user
    )
        external
        onlyLatestContract(pId, "projLightNode", address(this))
        onlyLatestContract(1, "stafiLightNode", msg.sender)
    {
        uint256 withdarwAmount = ProjSettings().getCurrentNodeDepositAmount();
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.withdrawEther(withdarwAmount);
        (bool success, ) = (_user).call{value: withdarwAmount}("");
        require(success, "transferr failed");
    }
}
