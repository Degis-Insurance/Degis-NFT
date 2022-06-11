require("@nomiclabs/hardhat-waffle");
require("hardhat-deploy")

require("@nomiclabs/hardhat-etherscan")

require('dotenv').config();

require("./tasks/DegisNFT.js")

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      }
    }
  },
  paths: {
    test: "test/hardhat",
    artifacts: "artifacts",
    cache: "hh-cache"
  },
  namedAccounts: {
    deployer: {
      default: 0,
      fuji: 0,
      avax: 0
    },
    testAddress: {
      default: 1,
      fuji: 1,
      avax: 1,
    },
  },
  etherscan: {
    apiKey: "I4IJTQGA3XWMBDU72J54UBC8FGMWR2ZCES"
  },
  networks: {
    fuji: {
      url: process.env.FUJI_URL || "",
      accounts: {
        mnemonic:
          process.env.PHRASE_FUJI !== undefined ? process.env.PHRASE_FUJI : "",
        count: 20,
      },
      timeout: 60000,
    },
    avaxTest: {
      url: process.env.AVAX_URL || "",
      accounts: {
        mnemonic:
          process.env.PHRASE_FUJI !== undefined ? process.env.PHRASE_FUJI : "",
        count: 20,
      },
      timeout: 60000,
    }
  }
};
