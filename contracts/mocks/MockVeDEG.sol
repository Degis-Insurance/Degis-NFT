// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockVeDEG is ERC20("MockVeDEG", "VeDEG") {
    address public nftStaking;

    constructor() {}

    function mint(address _to, uint256 _amount) public {
        _mint(_to, _amount);
    }

    function setNFTStaking(address _staking) public {
        nftStaking = _staking;
    }

    event Boost(address user, uint256 boostType);
    event UnBoost(address user);

    function boostVeDEG(address _user, uint256 _type) external {
        require(msg.sender == nftStaking, "only nft staking");

        emit Boost(_user, _type);
    }

    function unBoostVeDEG(address _user) external {
        require(msg.sender == nftStaking, "only nft staking");

        emit UnBoost(_user);
    }
}
