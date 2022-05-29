// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DegisNFT is ERC721, Ownable {
    using SafeERC20 for IERC20;

    // Status defined as constants rather than enum
    uint256 public constant STATUS_INIT = 0;
    uint256 public constant STATUS_AIRDROP = 1;
    uint256 public constant STATUS_ALLOWLIST = 2;
    uint256 public constant STATUS_PUBLICSALE = 3;

    address public constant DEG = 0x9f285507Ea5B4F33822CA7aBb5EC8953ce37A645;

    uint256 public constant MAX_SUPPLY = 499;

    uint256 public constant PRICE_PUBLICSALE = 1 ether;
    uint256 public constant PRICE_ALLOWLIST = 0.5 ether;

    uint256 public constant MAXAMOUNT_PUBLICSALE = 5;
    uint256 public constant MAXAMOUNT_ALLOWLIST = 3;

    // Current status of minting
    uint256 public status;

    // Amount of NFTs already minted
    // Current tokenId
    uint256 public mintedAmount;

    // wallet mapping that allows wallets to mint during airdrop and allowlist sale
    mapping(address => bool) public allowlistMinted;
    mapping(address => bool) public airdroplistClaimed;

    // amount minted on public sale per wallet
    mapping(address => uint256) public mintedOnPublic;

    string public baseURI;

    // Merkle root of airdrop list
    bytes32 public airdropMerkleRoot;

    // Merkle root of allowlist
    bytes32 public allowlistMerkleRoot;

    event StatusChange(uint256 oldStatus, uint256 newStatus);
    event SetBaseURI(string baseUri);
    event WithdrawERC20(
        address indexed token,
        uint256 amount,
        address receiver
    );

    /**
     * @notice Constructor
     *
     * @dev The initial status is Init (default as zero)
     */
    constructor() ERC721("DegisNFT", "DegisNFT") {}

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
        mintedAmount += 1;
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

        unchecked {
            mintedAmount += _quantity;
        }
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
            mintedAmount += _quantity;
        }
    }

    /**
     * @notice Withdraw avax by the owner
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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

    /**
     * @notice BaseURI
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

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
}
