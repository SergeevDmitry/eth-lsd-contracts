pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StafiBase.sol";
import "./interfaces/settings/IStafiNetworkSettings.sol";
import "./types/ProjectType.sol";
import "../project/ProjEther.sol";
import "../project/ProjBalances.sol";
import "../project/ProjDistributor.sol";
import "../project/ProjFeePool.sol";
import "../project/ProjLightNode.sol";
import "../project/ProjNodeManager.sol";
import "../project/ProjSettings.sol";
import "../project/ProjSuperNode.sol";
import "../project/ProjUserDeposit.sol";
import "../project/ProjWithdraw.sol";
import "../project/rToken.sol";

contract ContractManager is StafiBase {
    using SafeMath for uint256;

    event ProjectCreated(uint256 indexed id, Project proj);
    event ContractUpgraded(
        bytes32 indexed name,
        address indexed oldAddress,
        address indexed newAddress,
        uint256 pId,
        uint256 time
    );
    event ContractAdded(bytes32 indexed name, address indexed newAddress, uint256 pId, uint256 time);

    constructor(address _stafiStorageAddress) StafiBase(1, _stafiStorageAddress) {
        version = 1;
    }

    function StafiNetworkSettings() private view returns (IStafiNetworkSettings) {
        return IStafiNetworkSettings(getContractAddress(1, "stafiNetworkSettings"));
    }

    function getProjectNonce() public view returns (uint256) {
        return getUintS("contractManager.project.nonce");
    }

    function setProjectNonce(uint256 _nonce) private {
        setUintS("contractManager.project.nonce", _nonce);
    }

    function generateProjectId() private returns (uint256) {
        uint256 id = getProjectNonce();
        if (id == 0) id = 2;
        setProjectNonce(id.add(1));
        return id;
    }

    function setProjectContractAddress(uint256 _id, string memory _name, address _value) private {
        setAddress(contractAddressKey(_id, _name), _value);
    }

    function setProjectContractName(uint256 _pId, address _value, string memory _name) private {
        setString(contractNameKey(_pId, _value), _name);
    }

    function setProjectId(address _contractAddress, uint256 _pId) private {
        setUint(projectIdKey(_contractAddress), _pId);
    }

    function createProjUserDeposit(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address projUserDeposit = address(new UserDeposit(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projUserDeposit", projUserDeposit);
        setProjectContractName(_pId, projUserDeposit, "projUserDeposit");
        setProjectId(projUserDeposit, _pId);
        return projUserDeposit;
    }

    function createProjRToken(
        uint256 _pId,
        address _stafiStorageAddress,
        string memory _name,
        string memory _symbol
    ) private returns (address) {
        address rTokenAddress = address(new rToken(_pId, _stafiStorageAddress, _name, _symbol));
        setProjectContractAddress(_pId, "projrToken", rTokenAddress);
        setProjectContractName(_pId, rTokenAddress, "projrToken");
        setProjectId(rTokenAddress, _pId);
        return rTokenAddress;
    }

    function createProjEther(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address projEther = address(new ProjEther(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projEther", projEther);
        setProjectContractName(_pId, projEther, "projEther");
        setProjectId(projEther, _pId);
        return projEther;
    }

    function createProjBalances(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address balances = address(new ProjBalances(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projBalances", balances);
        setProjectContractName(_pId, balances, "projBalances");
        setProjectId(balances, _pId);
        return balances;
    }

    function createProjSettings(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address settings = address(new ProjSettings(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projSettings", settings);
        setProjectContractName(_pId, settings, "projSettings");
        setProjectId(settings, _pId);
        return settings;
    }

    function createProjNodeManager(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address nodeManager = address(new ProjNodeManager(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projNodeManager", nodeManager);
        setProjectContractName(_pId, nodeManager, "projNodeManager");
        setProjectId(nodeManager, _pId);
        return nodeManager;
    }

    function createProjFeePool(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address feePool = address(new ProjFeePool(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projFeePool", feePool);
        setProjectContractName(_pId, feePool, "projFeePool");
        setProjectId(feePool, _pId);
        return feePool;
    }

    function createProjLightNode(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address lightNode = address(new ProjLightNode(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projLightNode", lightNode);
        setProjectContractName(_pId, lightNode, "projLightNode");
        setProjectId(lightNode, _pId);
        return lightNode;
    }

    function createProjSuperNode(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address superNode = address(new ProjSuperNode(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projSuperNode", superNode);
        setProjectContractName(_pId, superNode, "projSuperNode");
        setProjectId(superNode, _pId);
        return superNode;
    }

    function createProjDistributor(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address distributor = address(new ProjDistributor(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projDistributor", distributor);
        setProjectContractName(_pId, distributor, "projDistributor");
        setProjectId(distributor, _pId);
        return distributor;
    }

    function createProjWithdraw(uint256 _pId, address _stafiStorageAddress) private returns (address) {
        address withdraw = address(new ProjWithdraw(_pId, _stafiStorageAddress));
        setProjectContractAddress(_pId, "projWithdraw", withdraw);
        setProjectContractName(_pId, withdraw, "projWithdraw");
        setProjectId(withdraw, _pId);
        return withdraw;
    }

    function createProject(
        string memory _name,
        string memory _symbol,
        address _superUser
    ) external onlySuperUser(1) returns (uint256) {
        Project memory proj;
        uint256 _pId = generateProjectId();
        address _stafiStorageAddress = address(stafiStorage);

        proj.pId = _pId;
        proj.balances = createProjBalances(_pId, _stafiStorageAddress);
        proj.distributor = createProjDistributor(_pId, _stafiStorageAddress);
        proj.feePool = createProjFeePool(_pId, _stafiStorageAddress);
        proj.lightNode = createProjLightNode(_pId, _stafiStorageAddress);
        proj.nodeManager = createProjNodeManager(_pId, _stafiStorageAddress);
        proj.rToken = createProjRToken(_pId, _stafiStorageAddress, _name, _symbol);
        proj.settings = createProjSettings(_pId, _stafiStorageAddress);
        proj.superNode = createProjSuperNode(_pId, _stafiStorageAddress);
        proj.projEther = createProjEther(_pId, _stafiStorageAddress);
        proj.userDeposit = createProjUserDeposit(_pId, _stafiStorageAddress);
        proj.withdraw = createProjWithdraw(_pId, _stafiStorageAddress);

        initializeStafiFeeRatio(_pId);
        setSuperUser(_pId, _superUser);

        emit ProjectCreated(_pId, proj);

        return _pId;
    }

    function setSuperUser(uint256 _pId, address _superUser) private {
        setBool(keccak256(abi.encodePacked("access.role", _pId, "owner", _superUser)), true);
    }

    function initializeStafiFeeRatio(uint256 _pId) private {
        IStafiNetworkSettings stafiSettings = StafiNetworkSettings();

        stafiSettings.initializeStafiFeeRatio(_pId, stafiSettings.getDefaultStafiFeeRatio());
    }

    // Upgrade contract
    function upgradeContract(
        uint256 _pId,
        string memory _name,
        address _contractAddress
    ) external onlyLatestContract(1, "stafiUpgrade", address(this)) onlySuperUser(_pId) {
        // Check contract being upgraded
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(nameHash != keccak256(abi.encodePacked("projEther")), "Cannot upgrade the stafi ether contract");
        require(nameHash != keccak256(abi.encodePacked("projRToken")), "Cannot upgrade token contracts");
        require(nameHash != keccak256(abi.encodePacked("ethDeposit")), "Cannot upgrade the eth deposit contract");
        // Get old contract address & check contract exists
        address oldContractAddress = getContractAddress(_pId, _name);
        require(oldContractAddress != address(0x0), "Contract does not exist");
        // Check new contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(_contractAddress != oldContractAddress, "The contract address cannot be set to its current address");
        // Register new contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setProjectContractName(_pId, _contractAddress, _name);
        setProjectContractAddress(_pId, _name, _contractAddress);
        // Deregister old contract
        deleteString(contractNameKey(_pId, oldContractAddress));
        deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
        // Emit contract upgraded event
        emit ContractUpgraded(nameHash, oldContractAddress, _contractAddress, _pId, block.timestamp);
    }

    // Add a new network contract
    function addContract(
        string memory _name,
        address _contractAddress
    ) external onlyLatestContract(1, "stafiContractManager", address(this)) onlySuperUser(1) {
        // Check contract name
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        require(nameHash != keccak256(abi.encodePacked("")), "Invalid contract name");
        require(getContractAddress(1, _name) == address(0x0), "Contract name is already in use");
        // Check contract address
        require(_contractAddress != address(0x0), "Invalid contract address");
        require(
            !getBool(keccak256(abi.encodePacked("contract.exists", _contractAddress))),
            "Contract address is already in use"
        );
        // Register contract
        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setProjectContractName(1, _contractAddress, _name);
        setProjectContractAddress(1, _name, _contractAddress);

        // Emit contract added event
        emit ContractAdded(nameHash, _contractAddress, pId, block.timestamp);
    }

    // Init stafi storage contract
    function initStorage(bool _value) external onlySuperUser(1) {
        setBool(keccak256(abi.encodePacked("contract.storage.initialised")), _value);
    }

    // Init stafi upgrade contract
    function initThisContract() external onlySuperUser(1) {
        addStafiContractManager(address(this));
    }

    // Upgrade stafi upgrade contract
    function upgradeThisContract(address _contractAddress) external onlySuperUser(1) {
        addStafiContractManager(_contractAddress);
    }

    // Add stafi upgrade contract
    function addStafiContractManager(address _contractAddress) private {
        string memory name = "stafiContractManager";
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        address oldContractAddress = getContractAddress(1, name);

        setBool(keccak256(abi.encodePacked("contract.exists", _contractAddress)), true);
        setProjectContractName(1, _contractAddress, name);
        setProjectContractAddress(1, name, _contractAddress);

        if (oldContractAddress != address(0x0)) {
            deleteString(keccak256(abi.encodePacked("contract.name", uint256(1), oldContractAddress)));
            deleteBool(keccak256(abi.encodePacked("contract.exists", oldContractAddress)));
        }
        // Emit contract added event
        emit ContractAdded(nameHash, _contractAddress, 1, block.timestamp);
    }
}
