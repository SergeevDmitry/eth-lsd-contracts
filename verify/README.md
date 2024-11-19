## Verify NewContractLib
```bash
$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/libraries/NewContractLib.sol:NewContractLib' \
  0x5EcA5FE81c56F324b0C21454D1a2fF4a2EBEAb78
```

## Verify LsdNetworkFactory
```bash
$ npx hardhat verify \
  --network auroria \
  --contract contracts/LsdNetworkFactory.sol:LsdNetworkFactory \
  --libraries ./verify/libraries.js \
  0xF6cd674Ffe4F52644B07413A877338a12666EFE1
```

## Verify contract related to LsdNetwork

verify logic contracts

```bash
$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/UserDeposit.sol:UserDeposit' \
  0x77D5353616C51e590e3c2EDb662935B2F73C262D

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NodeDeposit.sol:NodeDeposit' \
  0xb21968fD1A92Ba65D01F22Ded2B2cf491871B40E

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NetworkWithdraw.sol:NetworkWithdraw' \
  0x894BbBa1e824F4619FE4c3a3c99f1dE31E5bD368

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/FeePool.sol:FeePool' \
  0xD722d17BD5a50a3Ae8752bb7B7cba8D362321bA4

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NetworkBalances.sol:NetworkBalances' \
  0x90FC93B0ec8a8E9cD06d64Fd20Ade58Fd949cC2e

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NetworkProposal.sol:NetworkProposal' \
  0xcFe315344093029b6Ac8253B90De46e353613076
```