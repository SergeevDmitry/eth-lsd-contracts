pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only
import "./LsdToken.sol";
import "./interfaces/IDistributor.sol";
import "./interfaces/IFeePool.sol";
import "./interfaces/INetworkBalances.sol";
import "./interfaces/INetworkProposal.sol";
import "./interfaces/INodeDeposit.sol";
import "./interfaces/IUserDeposit.sol";
import "./interfaces/IUserWithdraw.sol";
import "./interfaces/ILsdNetworkFactory.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract LsdNetworkFactory is ILsdNetworkFactory {
    uint8 public version;
    address public factoryAdmin;
    address public ethDepositAddress;

    address public distributorLogicAddress;
    address public feePoolLogicAddress;
    address public networkBalancesLogicAddress;
    address public networkProposalLogicAddress;
    address public nodeDepositLogicAddress;
    address public userDepositLogicAddress;
    address public userWithdrawLogicAddress;

    modifier onlyFactoryAdmin() {
        require(factoryAdmin == msg.sender, "caller is not the admin");
        _;
    }

    constructor(
        address _factoryAdmin,
        address _ethDepositAddress,
        address _distributorLogicAddress,
        address _feePoolLogicAddress,
        address _networkBalancesLogicAddress,
        address _networkProposalLogicAddress,
        address _nodeDepositLogicAddress,
        address _userDepositLogicAddress,
        address _userWithdrawLogicAddress
    ) {
        require(_factoryAdmin != address(0), "not valid address");

        version = 1;
        factoryAdmin = _factoryAdmin;
        ethDepositAddress = _ethDepositAddress;
        distributorLogicAddress = _distributorLogicAddress;
        feePoolLogicAddress = _feePoolLogicAddress;
        networkBalancesLogicAddress = _networkBalancesLogicAddress;
        networkProposalLogicAddress = _networkProposalLogicAddress;
        nodeDepositLogicAddress = _nodeDepositLogicAddress;
        userDepositLogicAddress = _userDepositLogicAddress;
        userWithdrawLogicAddress = _userWithdrawLogicAddress;
    }

    // ------------ settings ------------

    function transferOwnership(address _newAdmin) public onlyFactoryAdmin {
        require(_newAdmin != address(0), "zero address");

        factoryAdmin = _newAdmin;
    }

    function setDistributorLogicAddress(address _distributorLogicAddress) public onlyFactoryAdmin {
        distributorLogicAddress = _distributorLogicAddress;
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
        distributorLogicAddress = _userDepositLogicAddress;
    }

    function setuserWithdrawLogicAddress(address _userWithdrawLogicAddress) public onlyFactoryAdmin {
        userWithdrawLogicAddress = _userWithdrawLogicAddress;
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

        (bool success, bytes memory data) = contracts.distributor.call(
            abi.encodeWithSelector(
                IDistributor.init.selector,
                contracts.networkProposal,
                contracts.feePool,
                contracts.userDeposit
            )
        );
        require(success, string(data));
        (success, data) = contracts.feePool.call(abi.encodeWithSelector(IFeePool.init.selector, contracts.distributor));
        require(success, string(data));

        (success, data) = contracts.networkBalances.call(
            abi.encodeWithSelector(INetworkBalances.init.selector, contracts.networkProposal)
        );
        require(success, string(data));

        (success, data) = contracts.networkProposal.call(
            abi.encodeWithSelector(INetworkProposal.init.selector, _voters, _threshold, _networkAdmin)
        );
        require(success, string(data));

        (success, data) = contracts.nodeDeposit.call(
            abi.encodeWithSelector(
                INodeDeposit.init.selector,
                contracts.userDeposit,
                ethDepositAddress,
                contracts.networkProposal,
                bytes.concat(bytes1(0x01), bytes11(0), bytes20(contracts.userWithdraw))
            )
        );
        require(success, string(data));

        (success, data) = contracts.userDeposit.call(
            abi.encodeWithSelector(
                IUserDeposit.init.selector,
                contracts.lsdToken,
                contracts.nodeDeposit,
                contracts.userWithdraw,
                contracts.distributor,
                contracts.networkProposal
            )
        );
        require(success, string(data));

        (success, data) = contracts.userWithdraw.call(
            abi.encodeWithSelector(
                IUserWithdraw.init.selector,
                contracts.lsdToken,
                contracts.userDeposit,
                contracts.distributor,
                contracts.networkProposal
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
        address distributor = deploy(salt, _proxyAdmin, distributorLogicAddress);

        address feePool = deploy(salt, _proxyAdmin, feePoolLogicAddress);
        address networkBalances = deploy(salt, _proxyAdmin, networkBalancesLogicAddress);
        address networkProposal = deploy(salt, _proxyAdmin, networkProposalLogicAddress);
        address nodeDeposit = deploy(salt, _proxyAdmin, nodeDepositLogicAddress);
        address userDeposit = deploy(salt, _proxyAdmin, userDepositLogicAddress);
        address userWithdraw = deploy(salt, _proxyAdmin, userWithdrawLogicAddress);

        address lsdToken = address(
            new LsdToken{salt: salt}(userDeposit, networkBalances, _lsdTokenName, _lsdTokenSymbol)
        );

        return
            NetworkContracts(
                distributor,
                feePool,
                networkBalances,
                networkProposal,
                nodeDeposit,
                userDeposit,
                userWithdraw,
                lsdToken
            );
    }
}
