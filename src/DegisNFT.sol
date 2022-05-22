// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract DegisNFT is ERC721 {
    enum Status {
        Init,
        AirdropClaim,
        AllowlistSale,
        PublicSale
    }
    Status public status;

    address public owner;

    event StatusChange(Status oldStatus, Status newStatus);

    error WrongStatus();

    constructor() ERC721("DegisNFT", "DegisNFT") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    function setStatus(Status _newStatus) external onlyOwner {
        emit StatusChange(status, _newStatus);
        status = _newStatus;
    }

    function airdropClaim() external {
        if (status != Status.AirdropClaim) revert WrongStatus();

        _mint(msg.sender, 1);
    }

    function allowlistSale() external {
        if (status != Status.AllowlistSale) revert WrongStatus();

        _mint(msg.sender, 1);
    }

    function publicSale() external {
        if (status != Status.PublicSale) revert WrongStatus();

        _mint(msg.sender, 1);
    }
}
