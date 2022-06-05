// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockVeDEG is ERC20("MockVeDEG", "VeDEG") {

    event boostedVeDEG(address _address, uint256 _multiplier);
    event unBoostedVeDEG(address _address);

    constructor() {}

    function boostVeDEG(address _address, uint256 _multiplier) external {
        emit boostedVeDEG(_address, _multiplier);
    }

    function unBoostVeDEG(address _address) external {
        emit unBoostedVeDEG(_address);
    }
}