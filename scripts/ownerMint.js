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

  const receiver = "0xA10f8ecb4d91Ae5CA3291d0bFF159bd5F882A5f5";

  // const tx = await nft.ownerMint(receiver, 10);
  // console.log("tx details:", await tx.wait());

  const tx = await nft.setBaseURI("https://degis.io/NFT_Images/");
  console.log("tx details:", await tx.wait());

  const balance = await nft.balanceOf(receiver);
  console.log("current balance:", balance)

  // const nftStaking = await hre.ethers.getContractFactory("NFTStaking");
  // const staking = nftStaking.attach(addressList[network.name].NFTStaking);

  // const tx = await staking.setDegisNFTContract(nftAddress);
  // console.log("tx details:", await tx.wait());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
