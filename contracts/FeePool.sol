// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./interfaces/IFeePool.sol";
import "./interfaces/IDepositEth.sol";
import "./interfaces/INetworkProposal.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// receive priority fee
contract FeePool is Initializable, UUPSUpgradeable, IFeePool {
    address public networkWithdrawAddress;
    address public networkProposalAddress;

    modifier onlyAdmin() {
        if (!INetworkProposal(networkProposalAddress).isAdmin(msg.sender)) {
            revert CallerNotAllowed();
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function init(address _networkWithdrawAddress, address _networkProposalAddress)
        public
        virtual
        override
        initializer
    {
        networkWithdrawAddress = _networkWithdrawAddress;
        networkProposalAddress = _networkProposalAddress;
    }

    function reinit() public virtual override reinitializer(1) {
        _reinit();
    }

    function _reinit() internal virtual {}

    function version() external view override returns (uint8) {
        return _getInitializedVersion();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    // Allow receiving ETH
    receive() external payable {}

    // Withdraws ETH to given address
    // Only accepts calls from network contracts
    function withdrawEther(uint256 _amount) external override {
        if (_amount == 0) {
            revert AmountZero();
        }
        if (msg.sender != networkWithdrawAddress) {
            revert CallerNotAllowed();
        }

        IDepositEth(msg.sender).depositEth{value: _amount}();

        // Emit ether withdrawn event
        emit EtherWithdrawn(_amount, block.timestamp);
    }
}
