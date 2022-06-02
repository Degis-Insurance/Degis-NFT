// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockDEG is ERC20("MockDEG", "DEG") {
    constructor() {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }
}
