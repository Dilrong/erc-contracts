import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC20 contract", function () {
  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();

    const contractFactory = await ethers.getContractFactory("ERC20Token");

    const contract = await contractFactory.deploy(
      "test20",
      "TEST20",
      10,
      100,
      owner.address
    );

    const ownerBalance = await contract.balanceOf(owner.address);

    expect(await contract.totalSupply()).to.equal(ownerBalance);
  });
});
