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

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IDegisNFT {
    function ownerOf (uint256 tokenId) external view returns (address);
    function safeTransferFrom (address from, address to, uint256 tokenId) external;
}

interface IveDEG {
    function updateNFTMultiplier(address _address, uint256 _multiplier) external;
}

/**
 * @title  StakingNFT
 * @notice This contract is for NFT staking on Degis
 * @dev    staked warriors are granted boosted veDEG emission by updating veDEG contract multiplier.
 *         It interacts with Degis NFTs only.
 *         Tokens with ID 1-99 will be granted a 1.5x multiplier.
 *         Tokens with ID 100-499 will be granted a 1.2x multiplier.  
 *         Only one NFT can be staked at a time.
 *         Tokens can be unstaked by the owner only.
 *         StakingNFT address must be set as an operator by owner through `ApprovalForAll` on the DegisNFT contract.     
 */
contract NFTStaking is Ownable, IERC721Receiver {

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    // degis NFT contract to receive from owner
    IDegisNFT public degisNFTContract;

    // veDEG contract to updateNFTMultiplier
    IveDEG public veDEGContract;

    // addresses to staked warriors map
    mapping(address => uint256) public champions;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event championReceived(address operator,address from,uint256 tokenId, bytes data);
    event championWithdrawn(uint256 tokenId, address to);

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @dev Returns the token ID given an address.
     * @param _address The public address of
     * @return The token Id of the staked NFT
     */
    function tokenOwnedBy(address _address) public view returns (uint256) {
        require(champions[_address], "Address not found in champions map");
        return champions[_address];
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @dev Set the address of the Degis NFT contract to interact with.
     * @param _degsNFT address of the Degis NFT contract
     */
    function setDegisNFTContract (address _degisNFT) external onlyOwner {
        degisNFTContract = IDegisNFT(_degisNFT);
    }

    /**
     * @dev Set the address of the Degis NFT contract to interact with.
     * @param _veDeg address of the veDEG contract
     */
    function setIveDEG (address _veDeg) external onlyOwner {
        veDEGContract = IveDEG(_veDeg);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @dev Stake a NFT. Only the owner can stake a NFT.
     * @param _tokenId ID of token to stake
     */
    function stakeChampion(uint256 _tokenId) external {
        require(degisNFTContract.ownerOf(_tokenId) != address(0), "token not owned");
        require(degisNFTContract.ownerOf(_tokenId) == msg.sender, "not owner of token");
        require(_tokenId != 0, "tokenId cannot be 0");
        // uint256 _multiplier = _tokenId <= 99 ? 15 : 12;
        // veDEGContract.updateNFTMultiplier(msg.sender,_multiplier);
        degisNFTContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        champions[msg.sender] = _tokenId;
    }

    /**
     * @dev Unstake a NFT. Only the owner can unstake a NFT.
     * @param _tokenId ID of token to unstake
     */
    function withdrawChampion(uint256 _tokenId) external {
        require(champions[msg.sender] == _tokenId, "not owner of token");
        // veDEGContract.updateNFTMultiplier(msg.sender, 10);
        degisNFTContract.safeTransferFrom(address(this), msg.sender, _tokenId);
        champions[msg.sender] = 0;
        emit championWithdrawn(_tokenId, msg.sender);
    }
}

    /**
     * @dev Required implementation by IERC721Receiver. Called once a token is received.
     * @param _operator This contract address
     * @param _from message sender
     * @param _tokenId ID of token received
     * @param _data additional data
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
        )
        external override returns(bytes4){
        return this.onERC721Received.selector;
        emit championReceived(operator, from, tokenId, data);
    }