const { expect, use } = require('chai')
const { parseUnits } = require('ethers/lib/utils')
const { ethers } = require('hardhat')
const { MerkleTree } = require('merkletreejs')
const { keccak256 } = ethers.utils

use(require('chai-as-promised'))


describe("Degis NFT Mint", function () {
    let dev_account, user1, user2, user3, user4;
    let deg;
    let nft;

    beforeEach(async function () {
        [dev_account, user1, user2, user3, user4] = await ethers.getSigners();

        const MockDEG = await ethers.getContractFactory("MockDEG");
        deg = await MockDEG.deploy();

        const DegisNFT = await ethers.getContractFactory("DegisNFT");
        nft = await DegisNFT.deploy();

        await nft.setDEG(deg.address);
    })


    describe("Constants settings", function () {
        it("should have the correct prices", async function () {
            expect(await nft.PRICE_PUBLICSALE()).to.equal(parseUnits("200", 18));
            expect(await nft.PRICE_ALLOWLIST()).to.equal(parseUnits("100"), 18);
        });

        it("should have the correct total supply", async function () {
            expect(await nft.MAX_SUPPLY()).to.equal(500);
        });

        it("should have the correct amounts", async function () {
            expect(await nft.MAXAMOUNT_PUBLICSALE()).to.equal(5);
            expect(await nft.MAXAMOUNT_ALLOWLIST()).to.equal(3);
        })
    })
})