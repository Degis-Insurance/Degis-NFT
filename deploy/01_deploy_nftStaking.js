const { ethers, network } = require("hardhat");
const { readAddressList, storeAddressList } = require("../scripts/contractAddress");

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) => {
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    const addressList = readAddressList();

    const nftAddress = addressList[network.name].DegisNFT;
    const veDEGAddress = addressList[network.name].VoteEscrowedDegis;

    console.log("nft:", nftAddress);
    console.log("veDEG:", veDEGAddress);

    // Proxy Admin contract artifact
    const nftStaking = await deploy("NFTStaking", {
        contract: "NFTStaking",
        from: deployer,
        args: [nftAddress, veDEGAddress],
        log: true,
    });
    addressList[network.name].NFTStaking = nftStaking.address;

    // Store the address list after deployment
    storeAddressList(addressList)
};

module.exports.tags = ['NFTStaking'];