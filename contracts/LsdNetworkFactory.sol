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
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract LsdNetworkFactory {
    struct NetworkContracts {
        address distributor;
        address feePool;
        address networkBalances;
        address networkProposal;
        address nodeDeposit;
        address userDeposit;
        address userWithdraw;
        address lsdToken;
    }

    address public admin;
    address public ethDepositAddress;

    address public distributorLogicAddress;
    address public feePoolLogicAddress;
    address public networkBalancesLogicAddress;
    address public networkProposalLogicAddress;
    address public nodeDepositLogicAddress;
    address public userDepositLogicAddress;
    address public userWithdrawLogicAddress;

    event LsdNetwork(NetworkContracts _contracts);

    modifier onlyAdmin() {
        require(admin == msg.sender, "caller is not the admin");
        _;
    }

    constructor(
        address _admin,
        address _ethDepositAddress,
        address _distributorLogicAddress,
        address _feePoolLogicAddress,
        address _networkBalancesLogicAddress,
        address _networkProposalLogicAddress,
        address _nodeDepositLogicAddress,
        address _userDepositLogicAddress,
        address _userWithdrawLogicAddress
    ) {
        require(_admin != address(0), "not valid address");

        admin = _admin;
        ethDepositAddress = _ethDepositAddress;
        distributorLogicAddress = _distributorLogicAddress;
        feePoolLogicAddress = _feePoolLogicAddress;
        networkBalancesLogicAddress = _networkBalancesLogicAddress;
        networkProposalLogicAddress = _networkProposalLogicAddress;
        nodeDepositLogicAddress = _nodeDepositLogicAddress;
        userDepositLogicAddress = _userDepositLogicAddress;
        userWithdrawLogicAddress = _userWithdrawLogicAddress;
    }

    function transferOwnership(address _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "zero address");

        admin = _newAdmin;
    }

    function setDistributorLogicAddress(address _distributorLogicAddress) public onlyAdmin {
        distributorLogicAddress = _distributorLogicAddress;
    }

    function setNetworkBalancesLogicAddress(address _networkBalancesLogicAddress) public onlyAdmin {
        networkBalancesLogicAddress = _networkBalancesLogicAddress;
    }

    function setNetworkProposalLogicAddress(address _networkProposalLogicAddress) public onlyAdmin {
        networkProposalLogicAddress = _networkProposalLogicAddress;
    }

    function setNodeDepositLogicAddress(address _nodeDepositLogicAddress) public onlyAdmin {
        nodeDepositLogicAddress = _nodeDepositLogicAddress;
    }

    function setUserDepositLogicAddress(address _userDepositLogicAddress) public onlyAdmin {
        distributorLogicAddress = _userDepositLogicAddress;
    }

    function setuserWithdrawLogicAddress(address _userWithdrawLogicAddress) public onlyAdmin {
        userWithdrawLogicAddress = _userWithdrawLogicAddress;
    }

    function createLsdNetwork(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol,
        address _proxyAdmin,
        address _networkAdmin,
        address[] memory _voters,
        uint256 _threshold
    ) public onlyAdmin {
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
