// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const XCurrency_factory = await ethers.getContractFactory("XCurrency");
  xcurrency = await XCurrency_factory.deploy(100000);
  await xcurrency.deployed();

  const GemGame_factory = await ethers.getContractFactory("GemGame");
  gemgame = await GemGame_factory.deploy();
  await gemgame.deployed();

  const GameItem_factory = await ethers.getContractFactory("GameItem");
  gameitem = await GameItem_factory.deploy();
  await gameitem.deployed();

  const NFT_Market_factory = await ethers.getContractFactory("NFT_Market");
  nftmarket = await NFT_Market_factory.deploy(5, xcurrency.address, gemgame.address);
  await nftmarket.deployed();

  console.log(
    `Market is deployed at  ${nftmarket.address} and gem 1155 deployed at ${gemgame.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
