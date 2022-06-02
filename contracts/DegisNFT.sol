// SPDX-License-Identifier: UNLICENSED

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  DegisNFT
 * @notice This contract is for Degis NFT minting and management
 * @dev    The token id starts from 1 rather than 0
 *         There are 499 NFTs to be minted which increase veDEG generation by 1.2x.
 *         The first 99 were allocated to community members and also have an increased boost of 1.5x.
 *         Those 99 will be airdropped.
 *         Then, through a priority sale, "allowlisted" wallets will be able to mint for X Degis.
 *         The rest will be sold during public sale for X Degis.
 */
contract DegisNFT is ERC721, Ownable {
    enum Status {
        Init,
        AirdropClaim,
        AllowlistSale,
        PublicSale
    }
    Status public status;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // Amount of NFTs already minted
    uint256 public mintedAmount;

    // Wallet map for the allowlisted wallets
    mapping(address => bool) public allowlist;

    // Wallet map for the airdrop wallets
    mapping(address => bool) public airdroplist;

    // Amount minted on public sale per wallet
    mapping(address => uint256) public mintedOnPublic;

    // Max supply of NFTs
    uint256 public constant maxMintSupply = 499;

    //Public mint cost
    uint256 public constant mintPrice = 1 ether;

    //Allowlist sale price
    uint256 public constant allowPrice = 0.5 ether;

    //Max amount of NFTs that can be minted on public sale
    uint256 public constant maxPublicSale = 5;

    //Max amount of NFTs that can be minted on allowlist sale
    uint256 public constant maxAllowlist = 3;

    //NFT Collection URI
    string public baseURI;

    event StatusChange(Status oldStatus, Status newStatus);
    event WithdrawERC20(
        address indexed token,
        uint256 amount,
        address receiver
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor() ERC721("DegisNFT", "DegisNFT") {
        status = Status.Init;
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice   check if address is able to mint during allowlist sale phase
     * @param _address address to check
     */
    function isAllowlist(address _wallet) external view returns (bool) {
        return allowlist[_wallet];
    }

    /**
     * @notice   check if address is able to claim airdrop during airdrop phase
     * @param _address address to check
     */
    function isAirdrop(address _wallet) external view returns (bool) {
        return airdroplist[_wallet];
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Set Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //   
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

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Claimable NFTs
     */
    function airdropClaim() external {
        require(status == Status.AirdropClaim, "Not in airdrop claim phase");
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
        require(status == Status.AllowlistSale, "Not in allowlist sale phase");
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
        require(status == Status.PublicSale, "Not in public sale phase");
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
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), 'owner index out of bounds');
        uint256 tokenIdsIdx;
        address currOwnershipAddr;
        unchecked {
            for (uint256 i = 1; i <= mintedAmount; i++) {
                address ownership = ownerOf(i);
                if (ownership != address(0)) {
                    currOwnershipAddr = ownership;
                }
                if (currOwnershipAddr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert("unable to get token of owner by index");
    }
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
     * @notice   withdraws specificed ERC20 and amount to owner
      * @param  _token ERC20 to withdraw
      * @param  _amount amount to withdraw
     */
    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
        emit WithdrawERC20(_token, _amount, msg.sender);
    }

    // ---------------------------------------------------------------------------------------- //
    // ********************************** Internal Functions ********************************** //
    // ---------------------------------------------------------------------------------------- //

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

    /**
     * @notice  returns baseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
