const hre = require("hardhat");

async function main() {

  const MarketplaceNFT = await hre.ethers.getContractFactory("MarketplaceNFT");
  const marketplacenft = await Greeter.deploy();

  await greeter.deployed();

  console.log("MarketplaceNFT deployed to:", marketplacenft.address);
}


main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
