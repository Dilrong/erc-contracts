import { HardhatUserConfig } from "hardhat/config";
import { config as dotEnvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-etherscan";
dotEnvConfig();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 99999,
          },
        },
      },
    ],
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  networks: {
    testnet: {
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.DEV_ALCHEMY_KEY}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    mainnet: {
      chainId: 1,
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.PROD_ALCHEMY_KEY}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    polygon: {
      chainId: 137,
      url: "https://polygon-rpc.com",
      accounts: [process.env.PRIVATE_KEY!],
    },
    mumbai: {
      chainId: 80001,
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  etherscan: {
    // apiKey: process.env.ETHERSCAN_KEY,
    apiKey: process.env.POLYGONSCAN_KEY,
  },
};

export default config;
