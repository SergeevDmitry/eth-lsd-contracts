require("hardhat-contract-sizer")
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-foundry");

// set proxy
const { ProxyAgent, setGlobalDispatcher } = require("undici");
const proxyAgent = new ProxyAgent('http://127.0.0.1:7890'); // change to yours
setGlobalDispatcher(proxyAgent)


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  networks: {
    mainnet: {
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
    },
    goerli: {
      url: "https://eth-goerli.g.alchemy.com/v2/ttJ0x4Zlxb_b7bdiX151hKUiYBdjYduG",
      // url: `${process.env.GOERLI_RPC_URL}`,
    }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: `${process.env.ETHERSCAN_KEY}`
  }
};
