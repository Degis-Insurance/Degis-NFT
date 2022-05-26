// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DegisNFT is ERC721, Ownable {
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
    mapping(address => bool) public allowlist;
    mapping(address => bool) public airdroplist;
    // amount minted on public sale per wallet
    mapping(address => uint256) public mintedOnPublic;

    uint256 public constant maxMintSupply = 499;
    uint256 public constant mintPrice = 1 ether;
    uint256 public constant allowPrice = 0.5 ether;
    uint256 public constant maxPublicSale = 5;
    uint256 public constant maxAllowlist = 3;

    string public baseURI;

    event StatusChange(Status oldStatus, Status newStatus);
    event WithdrawERC20(
        address indexed token,
        uint256 amount,
        address receiver
    );

    error WrongStatus();

    constructor() ERC721("DegisNFT", "DegisNFT") {
        status = Status.Init;
    }

    /**
     * @notice Change minting status
     * @param  _newStatus New minting status
     */
    function setStatus(uint256 _newStatus) external onlyOwner {
        emit StatusChange(status, Status(_newStatus));
        status = Status(_newStatus);
    }

    /**
     * @notice Set the base URI for the NFTs
     * @param  baseURI_ New base URI for the collection
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    /**
     * @notice Owner minting
     * @param  _quantity Amount of NFTs to mint
     */
    function ownerMint(uint256 _quantity) external onlyOwner {
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
    function allowlistSale(uint256 _quantity) external payable {
        if (status != Status.AllowlistSale) revert WrongStatus();
        require(allowlist[msg.sender], "Only allowlist wallets");

        uint256 amountToPay = _quantity * allowPrice;

        require(msg.value >= amountToPay, "Not enough ether");
        require(_quantity <= maxAllowlist, "Too many tokens");
        _mint(msg.sender, _quantity);
        allowlist[msg.sender] = false;
        mintedAmount += _quantity;

        if (msg.value > amountToPay) {
            payable(msg.sender).transfer(msg.value - amountToPay);
        }
    }

    /**
     * @notice  public sale mint. Allowed to mint several times as long as total per wallet is bellow maxPublicSale
     * @param  _quantity amount of NFTs to mint
     */
    function publicSale(uint256 _quantity) external payable {
        if (status != Status.PublicSale) revert WrongStatus();
        require(tx.origin == msg.sender, "No proxy transactions");

        uint256 amountToPay = _quantity * mintPrice;

        require(msg.value >= amountToPay, "Not enough ether");
        require(
            mintedOnPublic[msg.sender] + _quantity <= maxPublicSale,
            "Max public sale reached"
        );
        require(
            mintedOnPublic[msg.sender] + _quantity + mintedAmount <=
                maxMintSupply,
            "Max mint supply reached"
        );
        _mint(msg.sender, _quantity);
        mintedOnPublic[msg.sender] += _quantity;
        mintedAmount += _quantity;

        // Refund
        if (msg.value > amountToPay) {
            payable(msg.sender).transfer(msg.value - amountToPay);
        }
    }

    /**
     * @notice   adds wallets to airdrop list
     * @param  _addresses array of addresses to add to airdrop loop
     */
    function addWalletsAirdrop(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            airdroplist[_addresses[i]] = true;
        }
    }

    /**
     * @notice   adds wallets to allowlist
     * @param  _addresses array of addresses to add to airdrop loop
     */
    function addWalletsAllowlist(address[] calldata _addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            allowlist[_addresses[i]] = true;
        }
    }

    /**
     * @notice   withdraws funds to owner
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice   withdraws specificed ERC20 and amount to owner
      * @param  _token ERC20 to withdraw
      * @param  _amount amount to withdraw
     */
    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
        emit WithdrawERC20(_token, _amount, msg.sender);
    }

    /**
     * @notice   returns baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /**
     * @notice   mint multiple NFTs
      * @param  _to address to send NFTs to
      * @param  _amount amount to mint
     */
    function _mint(address _to, uint256 _amount) internal override {
        for (uint256 i = 1; i <= _amount; i++) {
            uint256 id = mintedAmount + i;
            super._mint(_to, id);
        }
    }
}
