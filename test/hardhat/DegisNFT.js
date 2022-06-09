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
        nft = await DegisNFT.deploy(deg.address);

        // await nft.setDEG(deg.address);
    })


    describe("Deployments", function () {
        it("should have the correct prices", async function () {
            expect(await nft.PRICE_PUBLICSALE()).to.equal(parseUnits("200", 18));
            expect(await nft.PRICE_ALLOWLIST()).to.equal(parseUnits("200"), 18);
        });

        it("should have the correct total supply", async function () {
            expect(await nft.MAX_SUPPLY()).to.equal(500);
        });

        it("should have the correct amounts", async function () {
            expect(await nft.MAXAMOUNT_PUBLICSALE()).to.equal(10);
            // expect(await nft.MAXAMOUNT_ALLOWLIST()).to.equal(3);
        });

        it("should have the correct init status", async function () {
            expect(await nft.status()).to.equal(await nft.STATUS_INIT());
        });

        it("should have the correct baseURI", async function () {
            expect(await nft.baseURI()).to.equal("");

            await nft.setBaseURI("https://degis.io");
            expect(await nft.baseURI()).to.equal("https://degis.io");

            // expect(await nft.tokenURI(1)).to.equal("https://degis.io/1")
        })
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
            await expect(nft.allowlistSale(proof_allowlist)).to.be.rejectedWith("Not in allowlist sale phase")
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
            expect(await nft.mintedAmount()).to.equal(1);
            // user1 has 1 nft
            expect(await nft.balanceOf(user1.address)).to.equal(1);
            // the owner of token id 1 is user1
            expect(await nft.ownerOf(1)).to.equal(user1.address);

            // Temporarily use a new proof
            const airdrop_list = [user1, user2];
            proof_airdrop = tree_airdrop.getHexProof(keccak256(airdrop_list[1].address))
            await expect(nft.connect(user2).airdropClaim(proof_airdrop)).to.emit(nft, "AirdropClaim").withArgs(user2.address, 2);

            // Check status
            expect(await nft.mintedAmount()).to.equal(2);
            // user1 has 1 nft
            expect(await nft.balanceOf(user2.address)).to.equal(1);
            // the owner of token id 1 is user1
            expect(await nft.ownerOf(2)).to.equal(user2.address);
        })

        it("should not be able to allowlist sale with no deg", async function () {
            await nft.setStatus(2);

            // No allowance
            await expect(nft.connect(user3).allowlistSale(proof_allowlist)).to.be.rejectedWith("ERC20: insufficient allowance");

            // No balance
            await deg.connect(user3).approve(nft.address, parseUnits("1000"));
            await expect(nft.connect(user3).allowlistSale( proof_allowlist)).to.be.rejectedWith("ERC20: transfer amount exceeds balance");
        })

        it("should be able to participate in allowlist sale", async function () {
            await nft.setStatus(2);

            await deg.mint(user3.address, parseUnits("1000"));
            await deg.connect(user3).approve(nft.address, parseUnits("1000"));

            await expect(nft.connect(user3).allowlistSale(proof_allowlist)).to.emit(nft, "AllowlistSale").withArgs(user3.address, 1, 1);

            // Check status
            expect(await nft.mintedAmount()).to.equal(1);
            // user3 has 1 nft
            expect(await nft.balanceOf(user3.address)).to.equal(1);
            // the owner of token id 1 is user3
            expect(await nft.ownerOf(1)).to.equal(user3.address);

            // Spend 100 deg for minting
            expect(await deg.balanceOf(user3.address)).to.equal(parseUnits("800"));
            expect(await deg.balanceOf(nft.address)).to.equal(parseUnits("200"));


            // Temporarily use a new proof
            await deg.mint(user4.address, parseUnits("1000"));
            await deg.connect(user4).approve(nft.address, parseUnits("1000"));


            const allowlist = [user3, user4];
            proof_allowlist = tree_allowlist.getHexProof(keccak256(allowlist[1].address))
            await expect(nft.connect(user4).allowlistSale(proof_allowlist)).to.emit(nft, "AllowlistSale").withArgs(user4.address, 1, 2);


            // Spend 100 deg for minting
            expect(await deg.balanceOf(user4.address)).to.equal(parseUnits("800"));
            expect(await deg.balanceOf(nft.address)).to.equal(parseUnits("400"));

        })
    })

    describe("Public Sale", function () {
        beforeEach(async function () {
            await deg.mint(dev_account.address, parseUnits("10000"));
            await deg.mint(user1.address, parseUnits("10000"));

            await deg.approve(nft.address, parseUnits("10000"));
            await deg.connect(user1).approve(nft.address, parseUnits("10000"));
        })

        it("should not be able to public sale before setting status", async function () {
            await expect(nft.publicSale(1)).to.be.revertedWith("Not in public sale phase");

            await nft.setStatus(1);
            await expect(nft.publicSale(1)).to.be.revertedWith("Not in public sale phase");

            await nft.setStatus(2);
            await expect(nft.publicSale(1)).to.be.revertedWith("Not in public sale phase");
        })

        it("should not be able to mint more than the maxAmount", async function () {
            await nft.setStatus(3);

            await expect(nft.publicSale(11)).to.be.revertedWith("Max public sale amount reached");

            await nft.publicSale(1);
            await expect(nft.publicSale(10)).to.be.revertedWith("Max public sale amount reached");
        })

        it("should be able to participate in public sale", async function () {
            await nft.setStatus(3);

            // Buy 1
            await expect(nft.publicSale(1)).to.emit(nft, "PublicSale").withArgs(dev_account.address, 1, 1);
            // Buy 2
            await expect(nft.publicSale(2)).to.emit(nft, "PublicSale").withArgs(dev_account.address, 2, 3);

            // Deg balance check
            expect(await deg.balanceOf(dev_account.address)).to.equal(parseUnits("9400"));
            expect(await deg.balanceOf(nft.address)).to.equal(parseUnits("600"));

            // Nft check
            expect(await nft.balanceOf(dev_account.address)).to.equal(3);
            expect(await nft.ownerOf(1)).to.equal(dev_account.address);
            expect(await nft.ownerOf(2)).to.equal(dev_account.address);
            expect(await nft.ownerOf(3)).to.equal(dev_account.address);


            // Another user public sale
            await expect(nft.connect(user1).publicSale(1)).to.emit(nft, "PublicSale").withArgs(user1.address, 1, 4);
            await expect(nft.connect(user1).publicSale(1)).to.emit(nft, "PublicSale").withArgs(user1.address, 1, 5);

            // Deg balance check
            expect(await deg.balanceOf(user1.address)).to.equal(parseUnits("9600"));
            expect(await deg.balanceOf(nft.address)).to.equal(parseUnits("1000"));

            // Nft check
            expect(await nft.balanceOf(user1.address)).to.equal(2);
            expect(await nft.ownerOf(4)).to.equal(user1.address);
            expect(await nft.ownerOf(5)).to.equal(user1.address);

        })
    })

    describe("Mixed sale", function () {
        let leaves_airdrop, tree_airdrop, root_airdrop;
        let leaves_allowlist, tree_allowlist, root_allowlist;

        let proof_airdrop_user1, proof_airdrop_user2, proof_allowlist, wrongProof_allowlist;

        beforeEach(async function () {
            await deg.mint(dev_account.address, parseUnits("100000"));
            await deg.mint(user1.address, parseUnits("100000"));
            await deg.mint(user2.address, parseUnits("100000"));
            await deg.mint(user3.address, parseUnits("100000"));
            await deg.mint(user4.address, parseUnits("100000"));

            await deg.approve(nft.address, parseUnits("100000"));
            await deg.connect(user1).approve(nft.address, parseUnits("100000"));
            await deg.connect(user2).approve(nft.address, parseUnits("100000"));
            await deg.connect(user3).approve(nft.address, parseUnits("100000"));
            await deg.connect(user4).approve(nft.address, parseUnits("100000"));

            const airdrop_list = [user1, user2];
            leaves_airdrop = airdrop_list.map(account => keccak256(account.address));
            tree_airdrop = new MerkleTree(leaves_airdrop, keccak256, { sort: true });
            root_airdrop = tree_airdrop.getHexRoot();

            const allowlist = [user3, user4];
            leaves_allowlist = allowlist.map(account => keccak256(account.address));
            tree_allowlist = new MerkleTree(leaves_allowlist, keccak256, { sort: true });
            root_allowlist = tree_allowlist.getHexRoot();

            await nft.setAirdropMerkleRoot(root_airdrop);
            await nft.setAllowlistMerkleRoot(root_allowlist);


            proof_airdrop_user1 = tree_airdrop.getHexProof(keccak256(airdrop_list[0].address))
            proof_airdrop_user2 = tree_airdrop.getHexProof(keccak256(airdrop_list[1].address))

            proof_allowlist_user3 = tree_allowlist.getHexProof(keccak256(allowlist[0].address))
            proof_allowlist_user4 = tree_allowlist.getHexProof(keccak256(allowlist[1].address))
        })

        it("should be able to finish the whole sale process", async function () {
            // Init status
            expect(await nft.status()).to.equal(await nft.STATUS_INIT());


            // Airdrop claim
            await nft.setStatus(1);
            expect(await nft.status()).to.equal(await nft.STATUS_AIRDROP());

            expect(await nft.mintedAmount()).to.equal(0);

            await nft.connect(user1).airdropClaim(proof_airdrop_user1);
            expect(await nft.mintedAmount()).to.equal(1);
            expect(await nft.balanceOf(user1.address)).to.equal(1);
            expect(await nft.ownerOf(1)).to.equal(user1.address);

            await nft.connect(user2).airdropClaim(proof_airdrop_user2);
            expect(await nft.mintedAmount()).to.equal(2);
            expect(await nft.balanceOf(user2.address)).to.equal(1);
            expect(await nft.ownerOf(2)).to.equal(user2.address);

            // Allowlist Sale
            await nft.setStatus(2);
            expect(await nft.status()).to.equal(await nft.STATUS_ALLOWLIST());

            await nft.connect(user3).allowlistSale(proof_allowlist_user3);
            expect(await nft.mintedAmount()).to.equal(3);
            expect(await nft.balanceOf(user3.address)).to.equal(1);
            expect(await nft.ownerOf(3)).to.equal(user3.address);
           

            await nft.connect(user4).allowlistSale(proof_allowlist_user4);
            expect(await nft.mintedAmount()).to.equal(4);
            expect(await nft.balanceOf(user4.address)).to.equal(1);
            expect(await nft.ownerOf(4)).to.equal(user4.address);
            

            // Public Sale
            await nft.setStatus(3);
            expect(await nft.status()).to.equal(await nft.STATUS_PUBLICSALE());

            await nft.publicSale(5);
            expect(await nft.mintedAmount()).to.equal(9);

            await nft.connect(user1).publicSale(5);
            expect(await nft.mintedAmount()).to.equal(14);

            await nft.connect(user2).publicSale(2);
            expect(await nft.mintedAmount()).to.equal(16);

            await nft.ownerMint(dev_account.address, 484);

            await expect(nft.ownerMint(dev_account.address, 1)).to.be.revertedWith("Exceed max supply");
            await expect(nft.connect(user2).publicSale(1)).to.be.revertedWith("Exceed max supply");

            // Some extra test for uri
            await nft.setBaseURI("https://degis.io/");
            expect(await nft.baseURI()).to.equal("https://degis.io/");

            expect(await nft.tokenURI(1)).to.equal("https://degis.io/1")
        })
    })

})