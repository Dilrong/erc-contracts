import { expect } from "chai";
import { ethers } from "hardhat";

import { IERC20, IERCFactory, ERC721Token } from "../typechain-types";

describe("Factory contract", function () {
  let factoryContract: IERCFactory;
  let ERC721Token: ERC721Token;

  before("Create new instance of factory contract", async () => {
    // contract
    const contract = await ethers.getContractFactory("ERCFactory");
    const deploy = await contract.deploy();
    factoryContract = await deploy.deployed();
  });

  it("Should use factory to deploy new ERC20 token", async () => {
    const [owner] = await ethers.getSigners();
    const ERC20TokenContract = await factoryContract.deployNewERC20Token(
      "Test20",
      "TEST20",
      18,
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
    const ERC721TokenContract = await factoryContract.deployNewERC721Token(
      "Test721",
      "TEST721"
    );

    const contract = await ERC721TokenContract.wait();

    ERC721Token = await ethers.getContractAt(
      "ERC721Token",
      contract.events![0].args!.tokenAddress
    );

    expect(await ERC721Token.symbol()).to.equal("TEST721");
  });

  it("Should mint a new ERC721 token", async () => {
    const [owner] = await ethers.getSigners();
    const uri = "https://test.io/test.png";
    const tx = await ERC721Token.newNft(owner.address, uri);

    const tokenId = (await tx.wait()).events![0].args!.tokenId;

    const erc721Owner = await ERC721Token.ownerOf(tokenId);
    const erc721Uri = await ERC721Token.tokenURI(tokenId);

    expect(erc721Owner).to.equal(owner.address);
    expect(erc721Uri).to.equal(uri);
  });
});
