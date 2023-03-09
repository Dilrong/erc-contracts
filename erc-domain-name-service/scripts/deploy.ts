import { ethers } from "hardhat";
import "dotenv/config";

async function main() {
  const contractFactory = await ethers.getContractFactory("");
  const contract = await contractFactory.deploy();
  await contract.deployed();
  console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
