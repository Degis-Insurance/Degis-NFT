// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDEG is ERC20("MockDEG", "DEG") {

    event boostVeDEG(_address, _multiplier);
    event unBoostVeDEG(_address);

    constructor() {}

    function boostVeDEG(address _address, uint256 _multiplier) external {
        emit boostVeDEG(_address, _multiplier);
    }

    function unBoostVeDEG(address _address) external {
        emit unBoostVeDEG(_address);
    }
}