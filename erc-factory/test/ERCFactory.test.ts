import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

import { IERC20, IERCFactory, ERC721Token } from "../typechain-types";

describe("Factory contract", function () {
  let ERC721Token: ERC721Token;

  async function factoryFixture() {
    const [owner] = await ethers.getSigners();
    const contract = await ethers.getContractFactory("ERCFactory");
    const deploy = await contract.deploy(owner.address);
    await deploy.deployed();

    return { owner, deploy };
  }

  it("Should use factory to deploy new ERC20 token", async () => {
    const { owner, deploy } = await loadFixture(factoryFixture);
    const ERC20TokenContract = await deploy.deployNewERC20Token(
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
    const { deploy } = await loadFixture(factoryFixture);
    const ERC721TokenContract = await deploy.deployNewERC721Token(
      "Test721",
      "TEST721",
      100
    );

    const contract = await ERC721TokenContract.wait();

    ERC721Token = await ethers.getContractAt(
      "ERC721Token",
      contract.events![0].args!.tokenAddress
    );

    expect(await ERC721Token.symbol()).to.equal("TEST721");
  });

  it("Should mint a new ERC721 token", async () => {
    const [user] = await ethers.getSigners();
    const uri = "https://test.io/test.png";
    const tx = await ERC721Token.mint(user.address, uri);
    const tokenId = (await tx.wait()).events![0].args!.tokenId;

    const erc721Owner = await ERC721Token.ownerOf(tokenId);
    const erc721Uri = await ERC721Token.tokenURI(tokenId);

    expect(erc721Owner).to.equal(user.address);
    expect(erc721Uri).to.equal(uri);
  });
});
