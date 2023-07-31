pragma solidity 0.8.19;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-only

import "../stafi/StafiBase.sol";
import "../stafi/interfaces/node/IStafiSuperNode.sol";
import "./interfaces/IDepositContract.sol";
import "./interfaces/IProjSuperNode.sol";
import "./interfaces/IProjSettings.sol";

contract ProjSuperNode is StafiBase, IProjSuperNode {
    event Deposited(address node, bytes pubkey, bytes validatorSignature);
    event Staked(address node, bytes pubkey);

    constructor(
        uint256 _pId,
        address _stafiStorageAddress
    ) StafiBase(_pId, _stafiStorageAddress) {
        version = 1;
    }

    event EtherDeposited(address indexed from, uint256 amount, uint256 time);

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

    function getSuperNodeDepositEnabled() public view returns (bool) {
        return
            getBool(
                keccak256(abi.encode("settings.superNode.deposit.enabled", pId))
            );
    }

    function setSuperNodeDepositEnabled(bool _value) public onlySuperUser(pId) {
        setBool(
            keccak256(abi.encode("settings.superNode.deposit.enabled", pId)),
            _value
        );
    }

    function getPubkeyVoted(
        bytes calldata _validatorPubkey,
        address user
    ) public view returns (bool) {
        return
            getBool(
                keccak256(
                    abi.encodePacked(
                        "superNode.memberVotes.",
                        pId,
                        _validatorPubkey,
                        user
                    )
                )
            );
    }

    function deposit(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external onlyLatestContract(pId, "projSuperNode", address(this)) {
        IStafiSuperNode stafiSuperNode = IStafiSuperNode(
            getContractAddress(1, "stafiSuperNode")
        );
        stafiSuperNode.deposit(
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
        onlyLatestContract(pId, "projSuperNode", address(this))
        onlyLatestContract(1, "stafiSuperNode", msg.sender)
    {
        EthDeposit().deposit{value: 1 ether}(
            _validatorPubkey,
            ProjSettings().getWithdrawalCredentials(),
            _validatorSignature,
            _depositDataRoot
        );
        emit Deposited(_user, _validatorPubkey, _validatorSignature);
    }

    function stake(
        bytes[] calldata _validatorPubkeys,
        bytes[] calldata _validatorSignatures,
        bytes32[] calldata _depositDataRoots
    ) external payable onlyLatestContract(pId, "projSuperNode", address(this)) {
        IStafiSuperNode projSuperNode = IStafiSuperNode(
            getContractAddress(1, "stafiSuperNode")
        );
        projSuperNode.stake(
            msg.sender,
            _validatorPubkeys,
            _validatorSignatures,
            _depositDataRoots
        );
    }

    function ethStake(
        address _user,
        bytes calldata _validatorPubkey,
        bytes calldata _validatorSignature,
        bytes32 _depositDataRoot
    )
        external
        onlyLatestContract(pId, "projSuperNode", address(this))
        onlyLatestContract(1, "stafiSuperNode", msg.sender)
    {
        // Send staking deposit to casper
        EthDeposit().deposit{value: 31 ether}(
            _validatorPubkey,
            ProjSettings().getWithdrawalCredentials(),
            _validatorSignature,
            _depositDataRoot
        );
        emit Staked(_user, _validatorPubkey);
    }
}
