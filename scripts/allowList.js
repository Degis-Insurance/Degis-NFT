const fs = require("fs");


const getAllowList = () => {
    const allowlist = JSON.parse(fs.readFileSync("info/allowlist.json", "utf-8"));
    return allowlist.list;
}

const getAirdrop = () => {
    const airdropList = JSON.parse(fs.readFileSync("info/airdrop.json", "utf-8"));
    return airdropList.list;
}

module.exports = {
    getAllowList,
    getAirdrop
}