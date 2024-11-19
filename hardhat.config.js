require("hardhat-contract-sizer")
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");
require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-chai-matchers")
require('dotenv').config()

// set proxy
if (process.env.HTTP_NETWORK_PROXY) {
  // set proxy
  console.log("using http proxy", process.env.HTTP_NETWORK_PROXY);
  const { ProxyAgent, setGlobalDispatcher } = require("undici");
  const proxyAgent = new ProxyAgent({
    uri: process.env.HTTP_NETWORK_PROXY,
    connect: {
      timeout: 30_000,
    }
  });
  setGlobalDispatcher(proxyAgent)
}

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
    stratis: {
      url: 'https://rpc.stratisevm.com',
    },
    auroria: {
      url: 'https://auroria.rpc.stratisevm.com',
    },
  },
  etherscan: {
    apiKey: {
      stratis: 'test',
      auroria: 'test',
    },
    customChains: [
      {
        network: "stratis",
        chainId: 105105,
        urls: {
          apiURL: "https://explorer.stratisevm.com/api",
          browserURL: "https://explorer.stratisevm.com"
        }
      },
      {
        network: "auroria",
        chainId: 205205,
        urls: {
          apiURL: "https://auroria.explorer.stratisevm.com/api",
          browserURL: "https://auroria.explorer.stratisevm.com"
        }
      }
    ]
  }
};
