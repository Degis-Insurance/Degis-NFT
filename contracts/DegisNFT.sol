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
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

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
    using SafeERC20 for IERC20;

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //
    
    // Status defined as constants rather than enum
    uint256 public constant STATUS_INIT = 0;
    uint256 public constant STATUS_AIRDROP = 1;
    uint256 public constant STATUS_ALLOWLIST = 2;
    uint256 public constant STATUS_PUBLICSALE = 3;

    // address public constant DEG = 0x9f285507Ea5B4F33822CA7aBb5EC8953ce37A645;
    address public DEG;

    // Total supply: 500
    uint256 public constant MAX_SUPPLY = 500;

    // Public sale price is 200 DEG
    uint256 public constant PRICE_PUBLICSALE = 200 ether;
    // Allowlist sale price is 100 DEG
    uint256 public constant PRICE_ALLOWLIST = 100 ether;

    //Max amount of NFTs that can be minted on public sale
    uint256 public constant MAXAMOUNT_PUBLICSALE = 5;

    //Max amount of NFTs that can be minted on allowlist sale
    uint256 public constant MAXAMOUNT_ALLOWLIST = 3;

    // Current status of minting
    uint256 public status;

    // Amount of NFTs already minted
    // Current tokenId
    uint256 public mintedAmount;

    // Wallet map for the allowlisted wallets
    mapping(address => bool) public allowlist;

    // Wallet map for the airdrop wallets
    mapping(address => bool) public airdroplist;

    // Amount minted on public sale per wallet
    mapping(address => uint256) public mintedOnPublic;

    //NFT Collection URI
    string public baseURI;

    // Merkle root of airdrop list
    bytes32 public airdropMerkleRoot;

    // Merkle root of allowlist
    bytes32 public allowlistMerkleRoot;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event StatusChange(uint256 oldStatus, uint256 newStatus);
    event SetBaseURI(string baseUri);
    event WithdrawERC20(
        address indexed token,
        uint256 amount,
        address receiver
    );
    event AirdropClaim(address user, uint256 tokenId);
    event AllowlistSale(address user, uint256 quantity, uint256 tokenId);
    event PublicSale(address user, uint256 quantity, uint256 tokenId);

    /**
     * @notice Constructor
     *
     * @dev The initial status is Init (default as zero)
     */
    constructor(address _degis) ERC721("DegisNFT", "DegisNFT") {
        DEG = _degis;
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
     *
     * @dev Only by the owner
     *
     * @param _newStatus New minting status
     */
    function setStatus(uint256 _newStatus) external onlyOwner {
        emit StatusChange(status, _newStatus);
        status = _newStatus;
    }

    function setDEG(address _deg) external onlyOwner {
        require(_deg != address(0), "Zero address");
        DEG = _deg;
    }

    /**
     * @notice Set the base URI for the NFTs
     *
     * @param  baseURI_ New base URI for the collection
     */
    function setBaseURI(string calldata baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    function setAirdropMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        airdropMerkleRoot = _merkleRoot;
    }

    function setAllowlistMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        allowlistMerkleRoot = _merkleRoot;
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
    function ownerMint(address _user, uint256 _quantity) external onlyOwner {
        require(mintedAmount < MAX_SUPPLY, "Exceed max supply");
        _mint(_user, _quantity);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Claimable NFTs
     */

    function airdropClaim(bytes32[] calldata _merkleProof) external {
        require(status == STATUS_AIRDROP, "Not in airdrop phase");
        require(!airdroplistClaimed[msg.sender], "already claimed");
        require(
            MerkleProof.verify(
                _merkleProof,
                airdropMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "invalid merkle proof"
        );
        airdroplistClaimed[msg.sender] = true;

        _mint(msg.sender, 1);

        emit AirdropClaim(msg.sender, mintedAmount);
    }

    /**
     * @notice Allowlist minting
     * @param  _quantity amount of NFTs to mint
     */

    function allowlistSale(uint256 _quantity, bytes32[] calldata _merkleProof)
        external
        payable
    {
        require(status == STATUS_ALLOWLIST, "Not in allowlist sale phase");
        require(!allowlistMinted[msg.sender], "already minted");
        require(_quantity <= MAXAMOUNT_ALLOWLIST, "Too many tokens");
        require(
            MerkleProof.verify(
                _merkleProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            ),
            "invalid merkle proof"
        );

        uint256 amountToPay = _quantity * PRICE_ALLOWLIST;

        // Transfer deg tokens
        IERC20(DEG).safeTransferFrom(msg.sender, address(this), amountToPay);

        _mint(msg.sender, _quantity);
        allowlistMinted[msg.sender] = true;

        emit AllowlistSale(msg.sender, _quantity, mintedAmount);
    }

    /**
     * @notice  public sale mint. Allowed to mint several times as long as total per wallet is bellow maxPublicSale
     * @param  _quantity amount of NFTs to mint
     */
    function publicSale(uint256 _quantity) external payable {
        require(status == STATUS_PUBLICSALE, "Not in public sale phase");
        require(tx.origin == msg.sender, "No proxy transactions");

        uint256 userAlreadyMinted = mintedOnPublic[msg.sender];
        require(
            userAlreadyMinted + _quantity <= MAXAMOUNT_PUBLICSALE,
            "Max public sale amount reached"
        );
        require(
            userAlreadyMinted + _quantity + mintedAmount <= MAX_SUPPLY,
            "Max mint supply reached"
        );

        // DEG to pay for minting
        uint256 amountToPay = _quantity * PRICE_PUBLICSALE;

        // Transfer DEG to this contract
        IERC20(DEG).safeTransferFrom(msg.sender, address(this), amountToPay);

        _mint(msg.sender, _quantity);

        unchecked {
            mintedOnPublic[msg.sender] += _quantity;
        }

        emit PublicSale(msg.sender, _quantity, mintedAmount);
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


    /**
     * @notice Owner minting
     * @param  _quantity Amount of NFTs to mint
     */
    function ownerMint(uint256 _quantity) external onlyOwner {
        _mint(msg.sender, _quantity);
        mintedAmount += _quantity;
    }

    /**
     * @notice Withdraw specificed ERC20 and amount to owner
     *
     * @param  _token  ERC20 to withdraw
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
     * @notice Mint multiple NFTs
     *
     * @param  _to     Address to mint NFTs to
     * @param  _amount Amount to mint
     */
    function _mint(address _to, uint256 _amount) internal override {
        uint256 alreadyMinted = mintedAmount;

        for (uint256 i = 1; i <= _amount; ) {
            super._mint(_to, ++alreadyMinted);

            unchecked {
                ++i;
            }
        }

        unchecked {
            mintedAmount += _amount;
        }
    }

    /**
     * @notice Checks if a given address is in the allowlist
     *
     * @param  _wallet wallet to verify   
     * @param  _merkleProof verification signature
     */
    function isAllowlist(address _wallet, bytes32[] calldata _merkleProof) external view returns (bool) {
        return MerkleProof.verify(_merkleProof, allowlistMerkleRoot, keccak256(abi.encodePacked(_wallet)));
    }

    /**
     * @notice Checks if a given address is in the airdrop
     *
     * @param  _wallet wallet to verify   
     * @param  _merkleProof verification signature
     */
    function isAirdrop(address _wallet, bytes32[] calldata _merkleProof) external view returns (bool) {
        return MerkleProof.verify(_merkleProof, airdropMerkleRoot, keccak256(abi.encodePacked(_wallet)));
    }
}
