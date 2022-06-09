
const { types, task } = require("hardhat/config");
const { getAllowList } = require("../scripts/allowList");
const { readAddressList } = require("../scripts/contractAddress");

require("@nomiclabs/hardhat-ethers")


const { MerkleTree } = require('merkletreejs');

const addressList = readAddressList();


task("setStatus", "Set status of nft contract")
    .addParam("status", "Status to be changed", null, types.int)
    .setAction(async (args, hre) => {
        const { network } = hre;

        const [dev_account] = await hre.ethers.getSigners();
        console.log("signer address:", dev_account.address);

        const nftFactory = await hre.ethers.getContractFactory("DegisNFT");
        const nftAddress = addressList[network.name].DegisNFT;
        const nft = nftFactory.attach(nftAddress);

        const initStatus = await nft.status();
        console.log("Init status: ", initStatus.toNumber());

        const tx = await nft.setStatus(args.status);
        console.log("Tx details:", await tx.wait());

        const currentStatus = await nft.status();
        console.log("Status after change: ", currentStatus.toNumber());
    })

task("setAllowlistRoot", "Set merkle root of allowlist")
    .setAction(async (_, hre) => {
        const { network } = hre;
        const { keccak256 } = hre.ethers.utils;


        const [dev_account] = await hre.ethers.getSigners();
        console.log("signer address:", dev_account.address);

        const allowlist = getAllowList();
        console.log("Full allowlist: ", allowlist);

        const leaves = allowlist.map(account => keccak256(account))
        const tree = new MerkleTree(leaves, keccak256, { sort: true })
        const merkleRoot = tree.getHexRoot();

        console.log("New root to set: ", merkleRoot);

        const nftFactory = await hre.ethers.getContractFactory("DegisNFT");
        const nftAddress = addressList[network.name].DegisNFT;
        const nft = nftFactory.attach(nftAddress);

        const tx = await nft.setAllowlistMerkleRoot(merkleRoot);
        console.log("Tx details: ", await tx.wait())
    })


task("ownerMint", "Owner mint some nfts")
    .addParam("address", "Receiver address", null, types.string)
    .addParam("amount", "Amount to mint", null, types.int)
    .setAction(async (args, hre) => {
        const { network } = hre;

        const [dev_account] = await hre.ethers.getSigners();
        console.log("signer address: ", dev_account.address);

        const nftFactory = await hre.ethers.getContractFactory("DegisNFT");
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

task("stake", "Stake nft")
    .addParam("id", "token id", null, types.int)
    .setAction(async (args, hre) => {
        const { network } = hre;

        const [dev_account] = await hre.ethers.getSigners();
        console.log("signer address: ", dev_account.address);

        const nftFactory = await hre.ethers.getContractFactory("DegisNFT");
        const nftAddress = addressList[network.name].DegisNFT;
        const nft = nftFactory.attach(nftAddress);

        const stakingFactory = await hre.ethers.getContractFactory("NFTStaking");
        const stakingAddress = addressList[network.name].NFTStaking;
        const staking = stakingFactory.attach(stakingAddress);

        const isOwner = await nft.ownerOf(args.id);
        console.log("owner of ", args.id, " is ", isOwner)

        const ve = await staking.veDEG();
        console.log("ve", ve);
        const nftinstaking = await staking.degisNFT();
        console.log("nft", nftinstaking)

        if (isOwner == dev_account.address) {

            const approve_tx = await nft.setApprovalForAll(staking.address, true);
            console.log("approve tx: ", await approve_tx.wait())

            const tx = await staking.stake(args.id);
            console.log("Tx details: ", await tx.wait())
        }
        else console.log("not owner")
    })