const { expect, use } = require('chai')
const { ethers } = require('hardhat')
const { MerkleTree } = require('merkletreejs')
const { keccak256 } = ethers.utils

use(require('chai-as-promised'))

describe('WhitelistSale', function () {
  it('allow only whitelisted accounts to mint', async () => {
    const accounts = await hre.ethers.getSigners()
    const allowlisted = accounts.slice(0, 5)
    const airdroplisted = accounts.slice(5, 10)
    const WrongStatus = new Error()

    const leaves = allowlisted.map(account => keccak256(account.address))
    const tree = new MerkleTree(leaves, keccak256, { sort: true })
    const merkleRoot = tree.getHexRoot()

    const WhitelistSale = await ethers.getContractFactory('DegisNFT')
    const whitelistSale = await WhitelistSale.deploy()
    await whitelistSale.deployed()
    await whitelistSale.setMerkleRoot(merkleRoot)

    const allowlistMerkleProof = tree.getHexProof(keccak256(allowlisted[0].address))
    const airdropMerkleProof = tree.getHexProof(keccak256(airdroplisted[0].address))

    await whitelistSale.setStatus(1)
    // await expect(whitelistSale.status()).to.equal("1");
    
    await expect(whitelistSale.connect(airdroplisted[0]).airdropClaim(airdropMerkleProof)).to.not.be.rejected;
    // await expect(whitelistSale.connect( allowlisted[0]).allowlistSale(3, merkleProof)).to.be.reverted;
    // await expect(whitelistSale.publicSale(1)).to.be.reverted;
    // await expect(whitelistSale.connect(notWhitelisted[0]).allowlistSale(invalidMerkleProof)).to.be.rejectedWith('invalid merkle proof')
  })
})