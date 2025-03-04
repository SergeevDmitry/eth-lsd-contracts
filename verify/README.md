## Verify NewContractLib
```bash
$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/libraries/NewContractLib.sol:NewContractLib' \
  0xf7c74241c02E649E206838cCE6d16B9bA4509021
```

## Verify LsdNetworkFactory
```bash
$ npx hardhat verify \
  --network auroria \
  --contract contracts/LsdNetworkFactory.sol:LsdNetworkFactory \
  --libraries ./verify/libraries.js \
  0x77c1aD583dbd80b29e7A97F002303aa559664739
```

## Verify contract related to LsdNetwork

verify logic contracts

```bash
$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/UserDeposit.sol:UserDeposit' \
  0xEf0fD41574bCD95F0163e03D77df658c940f9149

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NodeDeposit.sol:NodeDeposit' \
  0x2B3E6121a22DEf591D1B1FfE7B01EEF45ECaCEDA

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NetworkWithdraw.sol:NetworkWithdraw' \
  0xEDf0f8d602C44D52BC5c7d53439542493Ec60C2F

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/FeePool.sol:FeePool' \
  0x0126B3D7dc5b8A2870C964fDa8868202689a3699

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NetworkBalances.sol:NetworkBalances' \
  0x3378932e90Dbf0724EDfd470F5b2eAD2333D89eb

$ npx hardhat verify \
  --network auroria \
  --contract 'contracts/NetworkProposal.sol:NetworkProposal' \
  0x62f063bc8c0F51f94CD2DD2d1eaCcEF10DA97416
```