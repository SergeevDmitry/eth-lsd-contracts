pragma solidity 0.8.19;

// SPDX-License-Identifier: GPL-3.0-only

interface ILsdNetworkFactory {
    struct NetworkContracts {
        address _feePool;
        address _networkBalances;
        address _networkProposal;
        address _nodeDeposit;
        address _userDeposit;
        address _networkWithdraw;
        address _lsdToken;
    }

    event LsdNetwork(NetworkContracts _contracts);

    function createLsdNetwork(
        string memory _lsdTokenName,
        string memory _lsdTokenSymbol,
        address _proxyAdmin,
        address _networkAdmin,
        address[] memory _voters,
        uint256 _threshold
    ) external;
}
