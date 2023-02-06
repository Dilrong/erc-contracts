import { ethers } from "hardhat";
import "dotenv/config";

async function main() {
  const contractFactory = await ethers.getContractFactory("NftMarket");
  const contract = await contractFactory.deploy(
    process.env.ADMIN_ADDRESS!,
    process.env.TREASURY_ADDRESS!
  );
  await contract.deployed();
  console.log("Contract deployed to:", contract.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
