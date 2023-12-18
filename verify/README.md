## Verify NewContractLib
```bash
$ npx hardhat verify \
  --network holesky \
  --contract 'contracts/libraries/NewContractLib.sol:NewContractLib' \
  0xF41cFAF21e5f55CBFb3712C9F11B8CC0E78e64C8
```

## Verify LsdNetworkFactory
```bash
$ npx hardhat verify \
  --network holesky \
  --contract contracts/LsdNetworkFactory.sol:LsdNetworkFactory \
  --libraries ./verify/libraries.js \
  0xcd6b39180d669c889287dc654ed1a80484f77f54
```

## Verify contract related to LsdNetwork

verify logic contracts

```bash
$ npx hardhat verify \
  --network holesky \
  --contract 'contracts/UserDeposit.sol:UserDeposit' \
  0xb9F68498237Cc0ebD655fD9E9D7Dd6D78aB27FE4

$ npx hardhat verify \
  --network holesky \
  --contract 'contracts/NodeDeposit.sol:NodeDeposit' \
  0x97813c834c4a601CF13Cf969401E91fDAb917c44

$ npx hardhat verify \
  --network holesky \
  --contract 'contracts/NetworkWithdraw.sol:NetworkWithdraw' \
  0x4bf4df49F8Bc72a4e484443a14B827cb8c47c716

$ npx hardhat verify \
  --network holesky \
  --contract 'contracts/FeePool.sol:FeePool' \
  0x3C5EA15f6e702FcC0351605b867E9ff33E1fd6BF

$ npx hardhat verify \
  --network holesky \
  --contract 'contracts/NetworkBalances.sol:NetworkBalances' \
  0xE27Df917b7557f0B427c768e90819D1e6Db70F1E

$ npx hardhat verify \
  --network holesky \
  --contract 'contracts/NetworkProposal.sol:NetworkProposal' \
  0x5e44EFdb2F1D7b1bcaA34d622F8945786cBAdE43
```