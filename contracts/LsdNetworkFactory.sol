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
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract LsdNetworkFactory is ILsdNetworkFactory {
    uint8 public version;
    address public factoryAdmin;
    address public ethDepositAddress;

    address public feePoolLogicAddress;
    address public networkBalancesLogicAddress;
    address public networkProposalLogicAddress;
    address public nodeDepositLogicAddress;
    address public userDepositLogicAddress;
    address public networkWithdrawLogicAddress;

    mapping(address => NetworkContracts) public networkContractsOf;

    modifier onlyFactoryAdmin() {
        require(factoryAdmin == msg.sender, "caller is not the admin");
        _;
    }

    constructor(
        address _factoryAdmin,
        address _ethDepositAddress,
        address _feePoolLogicAddress,
        address _networkBalancesLogicAddress,
        address _networkProposalLogicAddress,
        address _nodeDepositLogicAddress,
        address _userDepositLogicAddress,
        address _networkWithdrawLogicAddress
    ) {
        require(_factoryAdmin != address(0), "not valid address");

        version = 1;
        factoryAdmin = _factoryAdmin;
        ethDepositAddress = _ethDepositAddress;
        feePoolLogicAddress = _feePoolLogicAddress;
        networkBalancesLogicAddress = _networkBalancesLogicAddress;
        networkProposalLogicAddress = _networkProposalLogicAddress;
        nodeDepositLogicAddress = _nodeDepositLogicAddress;
        userDepositLogicAddress = _userDepositLogicAddress;
        networkWithdrawLogicAddress = _networkWithdrawLogicAddress;
    }

    // Receive eth
    receive() external payable {}

    // ------------ settings ------------

    function transferOwnership(address _newAdmin) public onlyFactoryAdmin {
        require(_newAdmin != address(0), "zero address");

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
        require(success, "failed to transfer");
    }

    // ------------ user ------------

    function createLsdNetwork(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol,
        address _proxyAdmin,
        address _networkAdmin,
        address[] memory _voters,
        uint256 _threshold
    ) external override {
        require(_proxyAdmin != _networkAdmin, "admin must be different");

        bytes32 salt = keccak256(abi.encode(_lsdTokenName, _lsdTokenSymbol));
        NetworkContracts memory contracts = deployNetworkContracts(_lsdTokenName, _lsdTokenSymbol, salt, _proxyAdmin);
        networkContractsOf[contracts._lsdToken] = contracts;

        (bool success, bytes memory data) = contracts._feePool.call(
            abi.encodeWithSelector(IFeePool.init.selector, contracts._networkWithdraw)
        );
        require(success, string(data));

        (success, data) = contracts._networkBalances.call(
            abi.encodeWithSelector(INetworkBalances.init.selector, contracts._networkProposal)
        );
        require(success, string(data));

        (success, data) = contracts._networkProposal.call(
            abi.encodeWithSelector(INetworkProposal.init.selector, _voters, _threshold, _networkAdmin)
        );
        require(success, string(data));

        (success, data) = contracts._nodeDeposit.call(
            abi.encodeWithSelector(
                INodeDeposit.init.selector,
                contracts._userDeposit,
                ethDepositAddress,
                contracts._networkProposal,
                bytes.concat(bytes1(0x01), bytes11(0), bytes20(contracts._networkWithdraw))
            )
        );
        require(success, string(data));

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
        require(success, string(data));

        (success, data) = contracts._networkWithdraw.call(
            abi.encodeWithSelector(
                INetworkWithdraw.init.selector,
                contracts._lsdToken,
                contracts._userDeposit,
                contracts._networkProposal,
                contracts._feePool,
                address(this)
            )
        );
        require(success, string(data));

        emit LsdNetwork(contracts);
    }

    // ------------ helper ------------

    function deploy(bytes32 salt, address _admin, address _logicAddress) private returns (address) {
        return address(new TransparentUpgradeableProxy{salt: salt}(_logicAddress, _admin, ""));
    }

    function deployNetworkContracts(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol,
        bytes32 salt,
        address _proxyAdmin
    ) private returns (NetworkContracts memory) {
        address feePool = deploy(salt, _proxyAdmin, feePoolLogicAddress);
        address networkBalances = deploy(salt, _proxyAdmin, networkBalancesLogicAddress);
        address networkProposal = deploy(salt, _proxyAdmin, networkProposalLogicAddress);
        address nodeDeposit = deploy(salt, _proxyAdmin, nodeDepositLogicAddress);
        address userDeposit = deploy(salt, _proxyAdmin, userDepositLogicAddress);
        address networkWithdraw = deploy(salt, _proxyAdmin, networkWithdrawLogicAddress);

        address lsdToken = address(new LsdToken{salt: salt}(userDeposit, _lsdTokenName, _lsdTokenSymbol));

        return
            NetworkContracts(
                feePool,
                networkBalances,
                networkProposal,
                nodeDeposit,
                userDeposit,
                networkWithdraw,
                lsdToken
            );
    }
}
