// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/Pausable.sol";

contract DegisNFT is ERC721, Ownable, Pausable {
    enum Status {
        Init,
        AirdropClaim,
        AllowlistSale,
        PublicSale
    }
    Status public status;

    uint256 public mintedAmount;

    mapping (address => bool) public allowlist;
    mapping (address => bool) public airdroplist;
    mapping (address => uint256) public mintedOnPublic;


    uint256 public constant maxMintSupply = 499;
    uint256 public constant mintPrice = 1 ether;
    uint256 public constant allowPrice = 0.5 ether;
    uint256 public constant maxPublicSale = 5;
    uint256 public constant maxAllowlist = 3;

    string public baseURI;

    event StatusChange(Status oldStatus, Status newStatus);

    error WrongStatus();

    constructor() ERC721("DegisNFT", "DegisNFT") {
        status = Status.Init;
    }

    function setStatus(Status _newStatus) external onlyOwner {
        emit StatusChange(status, _newStatus);
        status = _newStatus;
    }

    function setBaseUri(string _baseURI) external onlyOwner {
        baseURI = _setbaseURI;
    }

    function ownerMint(uint quantity) external onlyOwner {   
        _mint(msg.sender, quantity);
        mintedAmount += quantity;
    }

    function airdropClaim() external {   
        if (status != Status.AirdropClaim) revert WrongStatus();
        require(airdroplist[msg.sender], "Only airdrop wallets");
        _mint(msg.sender, 1);
        airdroplist[msg.sender] = false;
        mintedAmount += 1;
    }

    function allowlistSale(uint quantity) external {
        if (status != Status.AllowlistSale) revert WrongStatus();
        require(allowlist[msg.sender], "Only allowlist wallets");
        require(msg.value >= quantity * allowPrice, "Not enough ether");
        require(quantity <= maxAllowlist, "Too many tokens");
        _mint(msg.sender, quantity);
        allowlist[msg.sender] = false;
        mintedAmount += quantity;
    }

    function publicSale(uint quantity) external payable {
        if (status != Status.PublicSale) revert WrongStatus();
        require(tx.origin == msg.sender, "No proxy transactions");
        require(msg.value >= quantity * mintPrice, "Not enough ether");
        require(mintedOnPublic[msg.sender] + quantity <= maxPublicSale, "Max public sale reached");
        require(mintedOnPublic[msg.sender] + quantity + mintedAmount <= maxMintSupply, "Max mint supply reached");
        _mint(msg.sender, quantity);
        mintedOnPublic[msg.sender] += quantity;
        mintedAmount += quantity;
    }

    function addWalletsAirdrop(address[] _addresses) external onlyOwner {
        for (uint i=0; i< _addresses.length; i++) {
            airdroplist[_addresses[i]] = true;
        }
    }
    function addWalletsAllowlist(address[] _addresses) external onlyOwner {
        for (uint i=0; i< _addresses.length; i++) {
            allowlist[_addresses[i]] = true;
        }
    }

    function withdraw() external onlyOwner {
        require(msg.sender.transfer(this.balance));
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }
}
