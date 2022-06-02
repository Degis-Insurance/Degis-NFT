const { expect, use } = require('chai')
const { parseUnits } = require('ethers/lib/utils')
const { ethers } = require('hardhat')
const { MerkleTree } = require('merkletreejs')
const { keccak256 } = ethers.utils

use(require('chai-as-promised'))


describe("Degis NFT Staking", function () {

    let dev_account, user1;
    let nft;
    let degis;
    let nftStaking;

    beforeEach(async function () {
        const degisNFT = await ethers.getContractFactory("DegisNFT");
        nft = await degisNFT.deploy();

        await nft.ownerMint(10);



        const DegisNFTStaking = await ethers.getContractFactory("StakingNFT");
        nftStaking = await DegisNFTStaking.deploy();

        
    });
})