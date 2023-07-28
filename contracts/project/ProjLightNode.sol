pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../stafi/StafiBase.sol";
import "../stafi/interfaces/node/IStafiLightNode.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IProjEther.sol";
import "./interfaces/IProjLightNode.sol";
import "./interfaces/IProjSettings.sol";

contract ProjLightNode is StafiBase, IProjLightNode {
    // Libs
    using SafeMath for uint256;

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event SetPubkeyStatus(bytes pubkey, uint256 status);
    event Deposited(
        address node,
        bytes pubkey,
        bytes validatorSignature,
        uint256 amount
    );
    event Staked(address node, bytes pubkey);

    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
    }

    // Deposit ETH from deposit pool
    // Only accepts calls from the StafiUserDeposit contract
    function depositEth()
        external
        payable
        override
        onlyLatestContract(pId, "projUserDeposit", msg.sender)
    {
        // Emit ether deposited event
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function EthDeposit() private view returns (IDepositContract) {
        return IDepositContract(getContractAddress(1, "ethDeposit"));
    }

    function ProjSettings() private view returns (IProjSettings) {
        return IProjSettings(getContractAddress(pId, "projSettings"));
    }

    function getLightNodeDepositEnabled() external view returns (bool) {
        return
            getBool(
                keccak256(abi.encode("settings.lightNode.deposit.enabled", pId))
            );
    }

    function getCurrentNodeDepositAmount() public view returns (uint256) {
        return
            getUint(keccak256(abi.encode("settings.node.deposit.amount", pId)));
    }

    function setLightNodeDepositEnabled(bool _value) public onlySuperUser(pId) {
        setBoolS("settings.lightNode.deposit.enabled", _value);
    }

    function deposit(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external payable onlyLatestContract(pId, "projLightNode", address(this)) {
        IStafiLightNode stafiLightNode = IStafiLightNode(
            getContractAddress(1, "stafiLightNode")
        );
        stafiLightNode.deposit(
            msg.sender,
            _validatorPubkeys,
            _validatorSignatures,
            _depositDataRoots
        );
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
        uint256 depositAmount = getCurrentNodeDepositAmount();
        // Send staking deposit to casper
        EthDeposit().deposit{value: depositAmount}(
            _validatorPubkey,
            ProjSettings().getWithdrawalCredentials(),
            _validatorSignature,
            _depositDataRoot
        );
        emit Deposited(
            _user,
            _validatorPubkey,
            _validatorSignature,
            depositAmount
        );
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
        uint256 stakeAmount = uint256(32 ether).sub(
            getCurrentNodeDepositAmount()
        );
        // Send staking deposit to casper
        EthDeposit().deposit{value: stakeAmount}(
            _validatorPubkey,
            ProjSettings().getWithdrawalCredentials(),
            _validatorSignature,
            _depositDataRoot
        );
        emit Staked(_user, _validatorPubkey);
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
        uint256 withdarwAmount = getCurrentNodeDepositAmount();
        IProjEther projEther = IProjEther(getContractAddress(pId, "projEther"));
        projEther.withdrawEther(withdarwAmount);
        (bool success, ) = (_user).call{value: withdarwAmount}("");
        require(success, "transferr failed");
    }
}
