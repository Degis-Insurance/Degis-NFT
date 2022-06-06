
const { types, task } = require("hardhat/config");
const { readAddressList } = require("../scripts/contractAddress");

require("@nomiclabs/hardhat-ethers")

const addressList = readAddressList();
const nftFactory = await hre.ethers.getContractFactory("DegisNFT");


task("setStatus", "Set status of nft contract")
    .addParam("status", "Status to be changed", null, types.int)
    .setAction(async (args, hre) => {
        const { network } = hre;

        const [dev_account] = await hre.ethers.getSigners();
        console.log("signer address:", dev_account.address);

        const nftAddress = addressList[network.name].DegisNFT;
        const nft = nftFactory.attach(nftAddress);

        const initStatus = await nft.status();
        console.log("Init status: ", initStatus.toNumber());

        const tx = await nft.setStatus(args.status);
        console.log("Tx details:", await tx.wait());

        const currentStatus = await nft.status();
        console.log("Status after change: ", currentStatus.toNumber());
    })


task("ownerMint", "Owner mint some nfts")
    .addParam("address", "Receiver address", null, types.string)
    .addParam("amount", "Amount to mint", null, types.int)
    .setAction(async (args, hre) => {
        const { network } = hre;

        const [dev_account] = await hre.ethers.getSigners();
        console.log("signer address: ", dev_account.address);

        const nftAddress = addressList[network.name].DegisNFT;
        const nft = nftFactory.attach(nftAddress);

        const alreadyMintedBefore = await nft.mintedAmount();
        console.log("Already minted before: ", alreadyMintedBefore.toNumber());

        const balanceBefore = await nft.balanceOf(args.address);
        console.log("NFT balance before: ", balanceBefore.toNumber())

        const tx = await nft.ownerMint(args.address, args.amount);
        console.log("Tx details: ", await tx.wait());

        const alreadyMintedAfter = await nft.mintedAmount();
        console.log("Already minted after: ", alreadyMintedAfter.toNumber());

        const balanceAfter = await nft.balanceOf(args.address);
        console.log("NFT balance after: ", balanceAfter.toNumber())
    })