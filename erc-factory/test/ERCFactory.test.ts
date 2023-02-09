import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

import { IERC20, ERC721Token } from "../typechain-types";

describe("Factory contract", function () {
  let ERC721Token: ERC721Token;

  async function factoryFixture() {
    const [owner] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("ERCFactory", owner);
    const deployContract = await contract.deploy(owner.address);
    await deployContract.deployed();

    return { owner, deployContract };
  }

  it("Should use factory to deploy new ERC20 token", async () => {
    const { owner, deployContract } = await loadFixture(factoryFixture);
    const ERC20TokenContract = await deployContract.deployNewERC20Token(
      "test20",
      "TEST20",
      10,
      100
    );

    const contract = await ERC20TokenContract.wait();

    const ERC20Token: IERC20 = await ethers.getContractAt(
      "ERC20",
      contract.events![0].address
    );

    const ownerBalance = await ERC20Token.balanceOf(owner.address);

    expect(await ERC20Token.totalSupply()).to.equal(ownerBalance);
  });

  it("Should use factory to deploy new ERC721 token", async () => {
    const { deployContract } = await loadFixture(factoryFixture);
    const ERC721TokenContract = await deployContract.deployNewERC721Token(
      "Test721",
      "TEST721",
      100
    );

    const contract = await ERC721TokenContract.wait();

    ERC721Token = await ethers.getContractAt(
      "ERC721Token",
      contract.events![0].address
    );

    await ERC721Token.deployed();

    expect(await ERC721Token.symbol()).to.equal("TEST721");
  });

  it("Should mint a new ERC721 token", async () => {
    const { owner } = await loadFixture(factoryFixture);
    const uri = "https://test.io/test/";

    await ERC721Token.mint(owner.address, 1);

    const erc721Owner = await ERC721Token.ownerOf(1);

    await ERC721Token.setBaseURI(uri);
    const erc721Uri = await ERC721Token.tokenURI(1);

    expect(erc721Owner).to.equal(owner.address);
    expect(erc721Uri).to.equal(`${uri}1.json`);
  });
});
