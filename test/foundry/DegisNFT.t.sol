// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "../../contracts/DegisNFT.sol";

contract DegisNFTTest is Test {
    DegisNFT nft;

    function setUp() public {
        nft = new DegisNFT();
    }

    function testIntialStatus() public {
        assertTrue(uint256(nft.status()) == 0);
    }

    function testSetStatus() public {
        nft.setStatus(1);
         assertTrue(uint256(nft.status()) == 1);
    }
}
