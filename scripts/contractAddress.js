/**
 * Remember to use this function in the root path of your hardhat project
 */

const fs = require("fs");

///
/// Deployed Contract Address Info Record
///
const readAddressList = function () {
    // const filePath = __dirname + "/address.json"
    return JSON.parse(fs.readFileSync("info/address.json", "utf-8"));
};

const storeAddressList = function (addressList) {
    fs.writeFileSync(
        "info/address.json",
        JSON.stringify(addressList, null, "\t")
    );
};

const clearAddressList = function () {
    const emptyList = {};
    fs.writeFileSync("info/address.json", JSON.stringify(emptyList, null, "\t"));
};

module.exports = {
    readAddressList,
    storeAddressList
}



