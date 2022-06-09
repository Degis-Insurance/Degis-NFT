const fs = require("fs");


const getAllowList = () => {
    const allowlist = JSON.parse(fs.readFileSync("info/allowlist.json", "utf-8"));
    return allowlist.list;
}

module.exports = {
    getAllowList
}