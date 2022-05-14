import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-contract-sizer";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import * as fs from "fs";

function mnemonic() {
  try {
    return fs.readFileSync("./mnemonic.txt").toString().trim();
  } catch (e) {
    console.log("Couldn't read mnemonic", e);
  }
  return "";
}

function deployerPk() {
  try {
    return fs.readFileSync("./pk.txt").toString().trim();
  } catch (e) {
    console.log("Couldn't read pk", e);
  }
  return "";
}

const infuraId = process.env.INFURA_ID;

module.exports = {
  networks: {
    hardhat: {
      chainId: 1337,
    },
    localhost: {
      url: "http://localhost:8545",
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/" + infuraId,
      accounts: [deployerPk()],
    },
    mainnet: {
      url: "https://mainnet.infura.io/v3/" + infuraId,
      accounts: [deployerPk()],
      gasPrice: 110000000000,
    },
  },
  etherscan: {
    apiKey: {
      // rinkeby: `${process.env.ETHERSCAN_API_KEY}`,
      // mainnet: `${process.env.ETHERSCAN_API_KEY}`,
    },
  },
  solidity: {
    version: "0.8.13",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  namedAccounts: {
    deployer: 0,
    dev: 1,
    fee: 2,
  },
  paths: {
    sources: "./contracts",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 6000000,
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v5",
    alwaysGenerateOverloads: false, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    // externalArtifacts: ["externalArtifacts/*.json"], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
  },
};