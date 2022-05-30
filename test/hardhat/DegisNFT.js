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


    describe("Deployments", function () {
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
        });

        it("should have the correct init status", async function () {
            expect(await nft.status()).to.equal(await nft.STATUS_INIT());
        });
    })

    describe("Airdrop Claim & Allowlist Sale", function () {
        let leaves_airdrop, tree_airdrop, root_airdrop;
        let leaves_allowlist, tree_allowlist, root_allowlist;

        let proof_airdrop, wrongProof_airdrop, proof_allowlist, wrongProof_allowlist;

        beforeEach(async function () {
            const airdrop_list = [user1, user2];
            leaves_airdrop = airdrop_list.map(account => keccak256(account.address));
            tree_airdrop = new MerkleTree(leaves_airdrop, keccak256, { sort: true });
            root_airdrop = tree_airdrop.getHexRoot();

            const allowlist = [user3, user4];
            leaves_allowlist = allowlist.map(account => keccak256(account.address));
            tree_allowlist = new MerkleTree(leaves_allowlist, keccak256, { sort: true });
            root_allowlist = tree_allowlist.getHexRoot();

            // get proofs
            proof_airdrop = tree_airdrop.getHexProof(keccak256(airdrop_list[0].address))
            wrongProof_airdrop = tree_airdrop.getHexProof(keccak256(allowlist[0].address))

            proof_allowlist = tree_allowlist.getHexProof(keccak256(allowlist[0].address))
            wrongProof_allowlist = tree_allowlist.getHexProof(keccak256(airdrop_list[0].address))

            await nft.setAirdropMerkleRoot(root_airdrop);
            await nft.setAllowlistMerkleRoot(root_allowlist);
        });

        it("should not be able to claim before setting status", async function () {
            await expect(nft.airdropClaim(proof_airdrop)).to.be.rejectedWith('Not in airdrop phase');
            await expect(nft.allowlistSale(1, proof_allowlist)).to.be.rejectedWith("Not in allowlist sale phase")
        });

        it("should not be able to claim by wrong proofs", async function () {
            await nft.setStatus(1);

            // Wrong user
            await expect(nft.airdropClaim(proof_airdrop)).to.be.rejectedWith("invalid merkle proof");

            // True user with wrong proof
            await expect(nft.connect(user1).airdropClaim(proof_allowlist)).to.be.rejectedWith("invalid merkle proof");
        })

        it("should be able to claim airdrops", async function () {
            await nft.setStatus(1);

            await expect(nft.connect(user1).airdropClaim(proof_airdrop)).to.emit(nft, "AirdropClaim").withArgs(user1.address, 1);

            // Check status
            // user1 has 1 nft
            expect(await nft.balanceOf(user1.address)).to.equal(1);
            // the owner of token id 1 is user1
            expect(await nft.ownerOf(1)).to.equal(user1.address);

            // Temporarily use a new proof
            const airdrop_list = [user1, user2];
            proof_airdrop = tree_airdrop.getHexProof(keccak256(airdrop_list[1].address))
            await expect(nft.connect(user2).airdropClaim(proof_airdrop)).to.emit(nft, "AirdropClaim").withArgs(user2.address, 2);

            // Check status
            // user1 has 1 nft
            expect(await nft.balanceOf(user2.address)).to.equal(1);
            // the owner of token id 1 is user1
            expect(await nft.ownerOf(2)).to.equal(user2.address);
        })
    })
})