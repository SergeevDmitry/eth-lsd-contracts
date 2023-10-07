pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "./LsdToken.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/INetworkBalances.sol";
import "./interfaces/INetworkProposal.sol";
import "./interfaces/INodeDeposit.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/INetworkWithdraw.sol";
import "./interfaces/ILsdNetworkFactory.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Timelock.sol";

contract LsdNetworkFactory is Initializable, UUPSUpgradeable, ILsdNetworkFactory {
    address public factoryAdmin;
    address public ethDepositAddress;
    address public feePoolLogicAddress;
    address public networkBalancesLogicAddress;
    address public networkProposalLogicAddress;
    address public nodeDepositLogicAddress;
    address public userDepositLogicAddress;
    address public networkWithdrawLogicAddress;

    mapping(address => NetworkContracts) public networkContractsOfLsdToken;
    mapping(address => address[]) private lsdTokensOf;

    modifier onlyFactoryAdmin() {
        if (msg.sender != factoryAdmin) {
            revert NotFactoryAdmin();
        }
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function init(
        address _factoryAdmin,
        address _ethDepositAddress,
        address _feePoolLogicAddress,
        address _networkBalancesLogicAddress,
        address _networkProposalLogicAddress,
        address _nodeDepositLogicAddress,
        address _userDepositLogicAddress,
        address _networkWithdrawLogicAddress
    ) public virtual initializer {
        if (_factoryAdmin == address(0)) {
            revert AddressNotAllowed();
        }
        factoryAdmin = _factoryAdmin;
        ethDepositAddress = _ethDepositAddress;
        feePoolLogicAddress = _feePoolLogicAddress;
        networkBalancesLogicAddress = _networkBalancesLogicAddress;
        networkProposalLogicAddress = _networkProposalLogicAddress;
        nodeDepositLogicAddress = _nodeDepositLogicAddress;
        userDepositLogicAddress = _userDepositLogicAddress;
        networkWithdrawLogicAddress = _networkWithdrawLogicAddress;
    }

    function reinit() public virtual override reinitializer(1) {
        _reinit();
    }

    function _reinit() internal virtual {}

    function version() external view override returns (uint8) {
        return _getInitializedVersion();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyFactoryAdmin {}

    // Receive eth
    receive() external payable {}

    // ------------ getter ------------

    function lsdTokensOfCreater(address _creater) public view returns (address[] memory) {
        uint256 length = lsdTokensOf[_creater].length;
        address[] memory list = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            list[i] = lsdTokensOf[_creater][i];
        }
        return list;
    }

    // ------------ settings ------------

    function transferOwnership(address _newAdmin) public onlyFactoryAdmin {
        if (_newAdmin == address(0)) {
            revert AddressNotAllowed();
        }

        factoryAdmin = _newAdmin;
    }

    function setNetworkBalancesLogicAddress(address _networkBalancesLogicAddress) public onlyFactoryAdmin {
        networkBalancesLogicAddress = _networkBalancesLogicAddress;
    }

    function setNetworkProposalLogicAddress(address _networkProposalLogicAddress) public onlyFactoryAdmin {
        networkProposalLogicAddress = _networkProposalLogicAddress;
    }

    function setNodeDepositLogicAddress(address _nodeDepositLogicAddress) public onlyFactoryAdmin {
        nodeDepositLogicAddress = _nodeDepositLogicAddress;
    }

    function setUserDepositLogicAddress(address _userDepositLogicAddress) public onlyFactoryAdmin {
        userDepositLogicAddress = _userDepositLogicAddress;
    }

    function setNetworkWithdrawLogicAddress(address _networkWithdrawLogicAddress) public onlyFactoryAdmin {
        networkWithdrawLogicAddress = _networkWithdrawLogicAddress;
    }

    function factoryClaim(address _recipient) external onlyFactoryAdmin {
        (bool success, ) = _recipient.call{value: address(this).balance}("");
        if (!success) {
            revert FailedToTransfer();
        }
    }

    // ------------ user ------------

    function createLsdNetwork(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol,
        address _networkAdmin,
        address[] memory _voters,
        uint256 _threshold
    ) external override {
        _createLsdNetwork(_lsdTokenName, _lsdTokenSymbol, _networkAdmin, _voters, _threshold);
    }

    function createLsdNetworkWithTimelock(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol,
        address[] memory _voters,
        uint256 _threshold,
        uint256 minDelay,
        address[] memory proposers
    ) external override {
        address networkAdmin = address(new Timelock(minDelay, proposers, proposers, msg.sender));
        _createLsdNetwork(_lsdTokenName, _lsdTokenSymbol, networkAdmin, _voters, _threshold);
    }

    // ------------ helper ------------

    function _createLsdNetwork(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol,
        address _networkAdmin,
        address[] memory _voters,
        uint256 _threshold
    ) private {
        NetworkContracts memory contracts = deployNetworkContracts(_lsdTokenName, _lsdTokenSymbol);
        networkContractsOfLsdToken[contracts._lsdToken] = contracts;
        lsdTokensOf[msg.sender].push(contracts._lsdToken);

        (bool success, bytes memory data) = contracts._feePool.call(
            abi.encodeWithSelector(IFeePool.init.selector, contracts._networkWithdraw, contracts._networkProposal)
        );
        if (!success) {
            revert FailedToCall();
        }

        (success, data) = contracts._networkBalances.call(
            abi.encodeWithSelector(INetworkBalances.init.selector, contracts._networkProposal)
        );
        if (!success) {
            revert FailedToCall();
        }

        (success, data) = contracts._networkProposal.call(
            abi.encodeWithSelector(INetworkProposal.init.selector, _voters, _threshold, _networkAdmin)
        );
        if (!success) {
            revert FailedToCall();
        }

        (success, data) = contracts._nodeDeposit.call(
            abi.encodeWithSelector(
                INodeDeposit.init.selector,
                contracts._userDeposit,
                ethDepositAddress,
                contracts._networkProposal,
                bytes.concat(bytes1(0x01), bytes11(0), bytes20(contracts._networkWithdraw))
            )
        );
        if (!success) {
            revert FailedToCall();
        }

        (success, data) = contracts._userDeposit.call(
            abi.encodeWithSelector(
                IUserDeposit.init.selector,
                contracts._lsdToken,
                contracts._nodeDeposit,
                contracts._networkWithdraw,
                contracts._networkProposal,
                contracts._networkBalances
            )
        );
        if (!success) {
            revert FailedToCall();
        }

        (success, data) = contracts._networkWithdraw.call(
            abi.encodeWithSelector(
                INetworkWithdraw.init.selector,
                contracts._lsdToken,
                contracts._userDeposit,
                contracts._networkProposal,
                contracts._networkBalances,
                contracts._feePool,
                address(this)
            )
        );
        if (!success) {
            revert FailedToCall();
        }

        emit LsdNetwork(contracts);
    }

    function deploy(address _logicAddress) private returns (address) {
        return address(new ERC1967Proxy(_logicAddress, ""));
    }

    function deployNetworkContracts(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol
    ) private returns (NetworkContracts memory) {
        address feePool = deploy(feePoolLogicAddress);
        address networkBalances = deploy(networkBalancesLogicAddress);
        address networkProposal = deploy(networkProposalLogicAddress);
        address nodeDeposit = deploy(nodeDepositLogicAddress);
        address userDeposit = deploy(userDepositLogicAddress);
        address networkWithdraw = deploy(networkWithdrawLogicAddress);

        address lsdToken = address(new LsdToken(userDeposit, _lsdTokenName, _lsdTokenSymbol));

        return
            NetworkContracts(
                feePool,
                networkBalances,
                networkProposal,
                nodeDeposit,
                userDeposit,
                networkWithdraw,
                lsdToken,
                block.number
            );
    }
}
