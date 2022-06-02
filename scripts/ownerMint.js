// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { network } = require("hardhat");
const hre = require("hardhat");
const { readAddressList } = require("./contractAddress");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  const addressList = readAddressList();

  const nftAddress = addressList[network.name].DegisNFT;
  console.log("NFT Address:", nftAddress);

  // We get the contract to deploy
  const DegisNFT = await hre.ethers.getContractFactory("DegisNFT");
  const nft = DegisNFT.attach(nftAddress);

  const receiver = "0xF84eb208b432bACBC417F109E929F432b64ffd7E";

  const tx = await nft.ownerMint(receiver, 10);
  console.log("tx details:", await tx.wait());

  const balance = await nft.balanceOf(receiver);
  console.log("current balance:", balance)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
