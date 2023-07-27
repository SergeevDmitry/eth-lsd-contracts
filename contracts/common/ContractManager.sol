pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./StafiBase.sol";
import "./types/ProjectType.sol";
import "../project/ProjEther.sol";
import "../project/rToken.sol";
import "../project/ProjUserDeposit.sol";
import "../project/ProjBalances.sol";

contract ContractManager is StafiBase {
    using SafeMath for uint256;

    constructor(address _stafiStorageAddress) StafiBase(_stafiStorageAddress) {}

    function projectNonceKey() internal pure returns (string memory) {
        return "contractManager.project.nonce"
    }

    function getProjectNonce() public view returns (uint256) {
        return getUintS(projectNonceKey());
    }

    function setProjectNonce(uint256 _nonce) internal {
        setUintS(projectNonceKey(), _nonce);
    }

    function useProjectId() internal returns (uint256) {
        uint256 id = getProjectNonce();
        if (id == 0) id = 1;
        setProjectNonce(id.add(1));
        return id;
    }

    function setProjectContractAddress(
        uint256 _id,
        string memory _name,
        address _value
    ) internal {
        setAddress(contractKey(_id, _name), _value);
    }

    function setProjectContractName(
        uint256 _pId,
        address _value,
        string memory name
    ) internal {
        setString(contractNameKey(_pId, _value), name);
    }

    function setProjectId(address _contractAddress, uint256 id) internal {
        setUint(projectIdKey(_contractAddress), id);
    }

    function saveProject(Project memory proj) internal {
        setProjectContractAddress(proj.id, "projrToken", proj.rToken);
        setProjectContractAddress(proj.id, "projEther", proj.etherKeeper);
        setProjectContractAddress(proj.id, "projUserDeposit", proj.userDeposit);
        setProjectContractAddress(proj.id, "projBalances", proj.balances);
        setProjectContractName(proj.id, proj.rToken, "projrToken");
        setProjectContractName(proj.id, proj.etherKeeper, "projEther");
        setProjectContractName(proj.id, proj.userDeposit, "projUserDeposit");
        setProjectContractName(proj.id, proj.balances, "projBalances")
        setProjectId(proj.rToken, proj.id);
        setProjectId(proj.etherKeeper, proj.id);
        setProjectId(proj.userDeposit, proj.id);
    }

    function newProject(
        string memory name,
        string memory symbol
    ) external onlySuperUser returns (uint256) {
        Project memory proj;
        uint256 pId = useProjectId();
        address  stafiStorageAddress = address(stafiStorage)
        proj.id = pId
        proj.rToken = address(new rToken(pId, stafiStorageAddress, name, symbol));
        proj.etherKeeper = address(new EtherKeeper());
        proj.userDeposit = address(
            new UserDeposit(proj.id, stafiStorageAddress)
        );
        proj.balances = address(new ProjBalances(proj.id, stafiStorageAddress))
        return proj.id;
    }
}
