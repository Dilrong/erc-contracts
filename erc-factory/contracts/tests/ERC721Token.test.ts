import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC721 contract", function () {
  it("Deployment should assign the token symbol", async function () {
    const contractFactory = await ethers.getContractFactory("ERC721Token");

    const contract = await contractFactory.deploy("test721", "TEST721");
    const ERC721Token = await contract.deployed();

    expect(await ERC721Token.symbol()).to.equal("TEST721");
  });
});
