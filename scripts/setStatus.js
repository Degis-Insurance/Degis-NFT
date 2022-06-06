// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { network, ethers, getNamedAccounts } = require("hardhat");
const hre = require("hardhat");
const { readAddressList } = require("./contractAddress");
const { MerkleTree } = require('merkletreejs');
const { parseUnits } = require("ethers/lib/utils");


async function main() {
    // Hardhat always runs the compile task when running scripts with its command
    // line interface.
    //
    // If this script is run directly using `node` you may want to call compile
    // manually to make sure everything is compiled
    // await hre.run('compile');

    const { keccak256 } = ethers.utils

    const { dev_account } = await getNamedAccounts();

    const addressList = readAddressList();

    const nftAddress = addressList[network.name].DegisNFT;
    console.log("NFT Address:", nftAddress);

    // We get the contract to deploy 
    const DegisNFT = await hre.ethers.getContractFactory("DegisNFT");
    const nft = DegisNFT.attach(nftAddress);

    const tx = await nft.setStatus(1);




}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
