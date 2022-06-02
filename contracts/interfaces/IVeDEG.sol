// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IVeDEG {
    function boostVeDEG(address _address, uint256 _multiplier) external;

    function unBoostVeDEG(address _address) external;
}
