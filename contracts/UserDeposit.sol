pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/IDepositEth.sol";
import "./interfaces/ILsdToken.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/INetworkWithdraw.sol";
import "./interfaces/INetworkProposal.sol";
import "./interfaces/INetworkBalances.sol";

contract UserDeposit is IUserDeposit {
    bool public initialized;
    uint8 public version;
    bool public depositEnabled;

    uint256 public minDeposit;

    address public lsdTokenAddress;
    address public nodeDepositAddress;
    address public networkWithdrawAddress;
    address public networkProposalAddress;
    address public networkBalancesAddress;

    modifier onlyAdmin() {
        require(INetworkProposal(networkProposalAddress).isAdmin(msg.sender), "not admin");
        _;
    }

    function init(
        address _lsdTokenAddress,
        address _nodeDepositAddress,
        address _networkWithdrawAddress,
        address _networkProposalAddress,
        address _networkBalancesAddress
    ) external override {
        require(!initialized, "already initialized");

        initialized = true;
        version = 1;
        depositEnabled = true;
        lsdTokenAddress = _lsdTokenAddress;
        nodeDepositAddress = _nodeDepositAddress;
        networkWithdrawAddress = _networkWithdrawAddress;
        networkProposalAddress = _networkProposalAddress;
        networkBalancesAddress = _networkBalancesAddress;
    }

    // ------------ getter ------------

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getRate() external view returns (uint256) {
        return INetworkBalances(networkBalancesAddress).getExchangeRate();
    }

    // ------------ settings ------------

    function setDepositEnabled(bool _value) public onlyAdmin {
        depositEnabled = _value;
    }

    function setMinimumDeposit(uint256 _value) public onlyAdmin {
        minDeposit = _value;
    }

    // ------------ user ------------

    function deposit() external payable override {
        require(depositEnabled, "deposit  disabled");
        require(msg.value >= minDeposit, "deposit amount is less than the minimum deposit size");

        uint256 lsdTokenAmount = INetworkBalances(networkBalancesAddress).getLsdTokenValue(msg.value);

        ILsdToken(lsdTokenAddress).mint(msg.sender, lsdTokenAmount);

        uint256 poolBalance = getBalance();
        uint256 totalMissingAmountForWithdraw = INetworkWithdraw(networkWithdrawAddress)
            .totalMissingAmountForWithdraw();

        if (poolBalance > 0 && totalMissingAmountForWithdraw > 0) {
            uint256 mvAmount = totalMissingAmountForWithdraw;
            if (poolBalance < mvAmount) {
                mvAmount = poolBalance;
            }
            INetworkWithdraw(networkWithdrawAddress).depositEthAndUpdateTotalMissingAmount{value: mvAmount}();

            // Emit excess withdrawn event
            emit ExcessWithdrawn(networkWithdrawAddress, mvAmount, block.timestamp);
        }
    }

    // ------------ network ------------

    // Withdraw excess balance
    function withdrawExcessBalance(uint256 _amount) external override {
        require(msg.sender == nodeDepositAddress || msg.sender == networkWithdrawAddress, "not allowed address");
        // Check amount
        require(_amount <= getBalance(), "insufficient balance for withdrawal");
        IDepositEth(msg.sender).depositEth{value: _amount}();
        // Emit excess withdrawn event
        emit ExcessWithdrawn(msg.sender, _amount, block.timestamp);
    }

    // Recycle a deposit from withdraw
    // Only accepts calls from  networkWithdraw
    function recycleNetworkWithdrawDeposit() external payable override {
        require(msg.sender == networkWithdrawAddress, "not networkWithdraw");
        // Emit deposit recycled event
        emit DepositRecycled(msg.sender, msg.value, block.timestamp);
    }
}
