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
    let veDEG;
    let nftStaking;

    beforeEach(async function () {
        [dev_account, user1] = await ethers.getSigners();

        const MockDEG = await ethers.getContractFactory("MockDEG");
        degis = await MockDEG.deploy();

        const MockVeDEG = await ethers.getContractFactory("MockVeDEG");
        veDEG = await MockVeDEG.deploy();



        const degisNFT = await ethers.getContractFactory("DegisNFT");
        nft = await degisNFT.deploy(degis.address);

        await nft.ownerMint(dev_account.address, 10);
        await nft.ownerMint(user1.address, 10);



        const DegisNFTStaking = await ethers.getContractFactory("NFTStaking");
        nftStaking = await DegisNFTStaking.deploy(nft.address, veDEG.address);

        await veDEG.setNFTStaking(nftStaking.address)


    });

    describe("Stake and Unstake", function () {

        it("should not be able to stake without approval", async function () {
            await expect(nftStaking.stake(1)).to.be.reverted;


            await nft.approve(nftStaking.address, 1);
            await expect(nftStaking.stake(1)).to.be.reverted;
        })

        it("should be able to stake nft", async function () {
            await nft.setApprovalForAll(nftStaking.address, true);
            // await nft.approve(nftStaking.address, 1);

            await expect(nftStaking.stake(1)).to.emit(nftStaking, "Stake").withArgs(dev_account.address, 1, 2);


            await expect(nftStaking.stake(1)).to.be.revertedWith("not owner of token")
            await expect(nftStaking.stake(2)).to.be.revertedWith("already staked")
        })

        it("should be able to unstake nft", async function () {
            await nft.setApprovalForAll(nftStaking.address, true);


            await expect(nftStaking.withdraw(1)).to.be.revertedWith("not owner of token")

            await nftStaking.stake(1);


            await expect(nftStaking.withdraw(1)).to.emit(nftStaking, "Unstake").withArgs(dev_account.address, 1);

            await expect(nftStaking.withdraw(1)).to.be.revertedWith("not owner of token");
            await expect(nftStaking.withdraw(2)).to.be.revertedWith("not owner of token")
        })

    })
})