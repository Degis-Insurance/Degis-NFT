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

    // Amount of NFTs already minted
    uint256 public mintedAmount;

    // wallet mapping that allows wallets to mint during airdrop and allowlist sale
    mapping (address => bool) public allowlist;
    mapping (address => bool) public airdroplist;
    // amount minted on public sale
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

    /**
     * @notice changes minting status
     * @param  _newStatus new minting status
     */
    function setStatus(Status _newStatus) external onlyOwner {
        emit StatusChange(status, _newStatus);
        status = _newStatus;
    }

    /**
     * @notice Sets the base URI for the NFTs
     * @param  _baseURI new base URI for the collection
     */
    function setBaseURI(string _baseURI) external onlyOwner {
        baseURI = _setbaseURI;
    }

    /**
     * @notice Owner minting
     * @param  _quantity amount of NFTs to mint
     */
    function ownerMint(uint _quantity) external onlyOwner {   
        _mint(msg.sender, _quantity);
        mintedAmount += _quantity;
    }

    /**
     * @notice Claimable NFTs
     */
    function airdropClaim() external {   
        if (status != Status.AirdropClaim) revert WrongStatus();
        require(airdroplist[msg.sender], "Only airdrop wallets");
        _mint(msg.sender, 1);
        airdroplist[msg.sender] = false;
        mintedAmount += 1;
    }

    /**
     * @notice Allowlist minting
     * @param  _quantity amount of NFTs to mint
     */
    function allowlistSale(uint _quantity) external {
        if (status != Status.AllowlistSale) revert WrongStatus();
        require(allowlist[msg.sender], "Only allowlist wallets");
        require(msg.value >= _quantity * allowPrice, "Not enough ether");
        require(_quantity <= maxAllowlist, "Too many tokens");
        _mint(msg.sender, _quantity);
        allowlist[msg.sender] = false;
        mintedAmount += _quantity;
    }


    /**
     * @notice  public sale mint. Allowed to mint several times as long as total per wallet is bellow maxPublicSale
     * @param  _quantity amount of NFTs to mint
     */
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

    /**
     * @notice   adds wallets to airdrop list
     * @param  _addresses array of addresses to add to airdrop loop
     */
    function addWalletsAirdrop(address[] _addresses) external onlyOwner {
        for (uint i=0; i< _addresses.length; i++) {
            airdroplist[_addresses[i]] = true;
        }
    }

     /**
     * @notice   adds wallets to allowlist
     * @param  _addresses array of addresses to add to airdrop loop
     */
    function addWalletsAllowlist(address[] _addresses) external onlyOwner {
        for (uint i=0; i< _addresses.length; i++) {
            allowlist[_addresses[i]] = true;
        }
    }

    /**
     * @notice   withdraws funds to owner
     */
    function withdraw() external onlyOwner {
        require(msg.sender.transfer(this.balance));
    }

}
