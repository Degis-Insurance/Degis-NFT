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

    // Proxy Admin contract artifact
    const degisNFT = await deploy("DegisNFT", {
        contract: "DegisNFT",
        from: deployer,
        args: [addressList[network.name].DegisToken],
        log: true,
    });
    addressList[network.name].DegisNFT = degisNFT.address;

    // Store the address list after deployment
    storeAddressList(addressList)
};

module.exports.tags = ['NFT'];