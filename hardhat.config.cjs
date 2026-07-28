require("@nomiclabs/hardhat-ethers");
require("@nomicfoundation/hardhat-verify");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

require("solidity-coverage");
require("hardhat-gas-reporter");

function accounts(key) {
  return key && key.startsWith("0x") ? [key] : [];
}

module.exports = {
  solidity: {
    version: "0.8.22",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },

  networks: {
    bscTestnet: {
      url: process.env.BSC_TESTNET_RPC,
      chainId: 97,
      accounts: accounts(process.env.BSC_TESTNET_PRIVATE_KEY || process.env.PRIVATE_KEY),
      timeout: 200000,
    },

    bsc: {
      url: process.env.BSC_MAINNET_RPC,
      chainId: 56,
      accounts: accounts(process.env.BSC_MAINNET_PRIVATE_KEY),
      timeout: 200000,
    },

    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      timeout: 200000,
    },
  },

  etherscan: {
	  apiKey: process.env.ETHERSCAN_API_KEY,
	},

  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    token: "BNB",
    coinmarketcap: process.env.CMC_API_KEY || "",
    showTimeSpent: true,
    outputFile: "gas-report.txt",
    noColors: true,
  },
};