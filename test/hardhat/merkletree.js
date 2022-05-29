const { expect, use } = require('chai')
const { ethers } = require('hardhat')
const { MerkleTree } = require('merkletreejs')
const { keccak256 } = ethers.utils

use(require('chai-as-promised'))

describe('airdropSale & allowlistSale', function () {
  it('allow only airdrop accounts to claim then allowlisted accounts to mint', async () => {
    const accounts = await hre.ethers.getSigners()
    const airdrop = accounts.slice(0, 5)
    const allowlist = accounts.slice(5, 10)

    //airdrop merkle tree
    const leaves = airdrop.map(account => keccak256(account.address))
    const tree = new MerkleTree(leaves, keccak256, { sort: true })
    const merkleRoot = tree.getHexRoot()

    //allowlist merkle tree
    const leaves2 = allowlist.map(account => keccak256(account.address))
    const tree2 = new MerkleTree(leaves2, keccak256, { sort: true })
    const merkleRoot2 = tree2.getHexRoot()

    const WhitelistSale = await ethers.getContractFactory('DegisNFT')
    const whitelistSale = await WhitelistSale.deploy()

    await whitelistSale.deployed()
    await whitelistSale.setStatus(1)
    await whitelistSale.setAirdropMerkleRoot(merkleRoot)
    await whitelistSale.setAllowlistMerkleRoot(merkleRoot2)

    const merkleProof = tree.getHexProof(keccak256(airdrop[0].address))
    const invalidMerkleProof = tree.getHexProof(keccak256(allowlist[0].address))

    const merkleProof2 = tree2.getHexProof(keccak256(allowlist[0].address))
    const invalidMerkleProof2 = tree2.getHexProof(keccak256(airdrop[0].address))

    await expect(whitelistSale.airdropClaim(merkleProof)).to.not.be.rejected
    await expect(whitelistSale.airdropClaim(merkleProof)).to.be.rejectedWith('already claimed')
    await expect(whitelistSale.connect(allowlist[0]).airdropClaim(invalidMerkleProof)).to.be.rejectedWith('invalid merkle proof')

    await expect(whitelistSale.connect(allowlist[0]).allowlistSale(1, merkleProof2)).to.be.rejectedWith('Not in allowlist sale phase')

    await whitelistSale.setStatus(2)
    try {
      await expect(whitelistSale.connect(allowlist[0]).allowlistSale(1, merkleProof2, {value: ethers.utils.parseEther("1")})).to.not.be.rejected
      await expect(whitelistSale.connect(allowlist[0]).allowlistSale(1, merkleProof2, {value: ethers.utils.parseEther("1")})).to.be.rejectedWith('already minted')
    } catch (error){
      console.log(error)
    }
    await expect(whitelistSale.connect(airdrop[0]).allowlistSale(1, invalidMerkleProof2, {value: ethers.utils.parseEther("1")})).to.be.rejectedWith('invalid merkle proof')
  })
})

describe("public sale", function(){
  it("should be able to have public sale", async function() {
    
  })
})