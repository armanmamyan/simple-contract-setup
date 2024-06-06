const { ethers } = require("hardhat");

async function main() {
  const SimpleNFTContract = await ethers.getContractFactory("SimpleNFTContract");
  const merkleRoot = ethers.utils.formatBytes32String("merkleRoot");

  console.log("Deploying contract...");
  const simpleNFTContract = await SimpleNFTContract.deploy(
    "https://example.com/metadata/",
    merkleRoot
  );

  await simpleNFTContract.deployed();

  console.log("SimpleNFTContract deployed to:", simpleNFTContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
