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