import { HardhatUserConfig } from "hardhat/config";
import { config as dotEnvConfig } from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
dotEnvConfig();

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    goerli: {
      chainId: 5,
      url: `https://eth-goerli.alchemyapi.io/v2/${process.env.DEV_ALCHEMY_KEY}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
    ether: {
      chainId: 1,
      url: `https://eth-mainnet.g.alchemy.com/v2/${process.env.PROD_ALCHEMY_KEY}`,
      accounts: [process.env.PRIVATE_KEY!],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
};

export default config;
