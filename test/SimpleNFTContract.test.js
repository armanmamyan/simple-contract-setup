const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SimpleNFTContract", function () {
  let SimpleNFTContract, simpleNFTContract, owner, addr1, addr2;

  beforeEach(async function () {
    SimpleNFTContract = await ethers.getContractFactory("SimpleNFTContract");
    [owner, addr1, addr2, _] = await ethers.getSigners();
    simpleNFTContract = await SimpleNFTContract.deploy(
      "https://example.com/metadata/",
      ethers.utils.formatBytes32String("merkleRoot")
    );
    await simpleNFTContract.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await simpleNFTContract.owner()).to.equal(owner.address);
    });

    it("Should set the right base URI", async function () {
      expect(await simpleNFTContract._baseURI()).to.equal("https://example.com/metadata/");
    });
  });

  describe("Minting", function () {
    it("Should mint a new token", async function () {
      await simpleNFTContract.toggleSaleStatus();
      await simpleNFTContract.connect(addr1).mint(1, { value: ethers.utils.parseEther("0.03") });
      expect(await simpleNFTContract.totalSupply()).to.equal(1);
      expect(await simpleNFTContract.balanceOf(addr1.address)).to.equal(1);
    });

    it("Should not allow minting more than the maximum allowed per wallet", async function () {
      await simpleNFTContract.toggleSaleStatus();
      await expect(
        simpleNFTContract.connect(addr1).mint(6, { value: ethers.utils.parseEther("0.18") })
      ).to.be.revertedWith("Invalid mint amount or minted max amount already.");
    });
  });

  describe("Presale Minting", function () {
    it("Should mint during presale with valid merkle proof", async function () {
      // Assuming we have a valid merkle proof setup
      const merkleProof = []; // replace with actual proof
      await simpleNFTContract.togglePresaleActive();
      await simpleNFTContract.connect(addr1).preSaleMint(merkleProof, 1, { value: ethers.utils.parseEther("0.01") });
      expect(await simpleNFTContract.totalSupply()).to.equal(1);
      expect(await simpleNFTContract.balanceOf(addr1.address)).to.equal(1);
    });

    it("Should not mint during presale with invalid merkle proof", async function () {
      const merkleProof = []; // invalid proof
      await simpleNFTContract.togglePresaleActive();
      await expect(
        simpleNFTContract.connect(addr1).preSaleMint(merkleProof, 1, { value: ethers.utils.parseEther("0.01") })
      ).to.be.revertedWith("Address does not exist in list");
    });
  });

  describe("Withdraw", function () {
    it("Should allow the owner to withdraw funds", async function () {
      await simpleNFTContract.toggleSaleStatus();
      await simpleNFTContract.connect(addr1).mint(1, { value: ethers.utils.parseEther("0.03") });
      
      const initialBalance = await ethers.provider.getBalance(owner.address);
      await simpleNFTContract.withdraw();
      const finalBalance = await ethers.provider.getBalance(owner.address);
      
      expect(finalBalance).to.be.gt(initialBalance);
    });

    it("Should not allow non-owner to withdraw funds", async function () {
      await expect(simpleNFTContract.connect(addr1).withdraw()).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});
