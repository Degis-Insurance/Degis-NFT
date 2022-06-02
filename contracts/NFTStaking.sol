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

import {IDegisNFT} from "./interfaces/IDegisNFT.sol";
import {IVeDEG} from "./interfaces/IVeDEG.sol";

/**
 * @title  NFTStaking
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

    IDegisNFT public degisNFT;
    IVeDEG public veDEG;

    mapping(address => uint256) public champions;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event championReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );
    event championWithdrawn(uint256 tokenId, address to);

    constructor(address _degisNFT, address _veDEG) {
        degisNFT = IDegisNFT(_degisNFT);
        veDEG = IVeDEG(_veDEG);
    }

    // ---------------------------------------------------------------------------------------- //
    // *********************************** View Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @dev Returns the token ID given an address.
     * @param _address The public address of
     * @return tokenId of the staked NFT
     */
    function tokenStakedBy(address _address) public view returns (uint256) {
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
    function setDegisNFTContract(address _degisNFT) external onlyOwner {
        degisNFT = IDegisNFT(_degisNFT);
    }

     /* @notice Set veDEG contract
     *
     * @param _veDEG VeDEG address
     */
    function setVeDEG(address _veDEG) external onlyOwner {
        veDEG = IVeDEG(_veDEG);
    }


    // ---------------------------------------------------------------------------------------- //
    // *********************************** Main Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @dev Stake a NFT. Only the owner can stake a NFT.
     * @param _tokenId ID of token to stake
     */
    function stake(uint256 _tokenId) external {
        require(degisNFT.ownerOf(_tokenId) == msg.sender, "not owner of token");
        require(_tokenId != 0, "tokenId cannot be 0");

        require(champions[msg.sender] == 0, "already staked");

        degisNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        champions[msg.sender] = _tokenId;

        uint256 boostType = _tokenId > 99 ? 2 : 1;
        veDEG.boostVeDEG(msg.sender, boostType);
    }

    /**
     * @dev Unstake a NFT. Only the owner can unstake a NFT.
     * @param _tokenId ID of token to unstake
     */
    function withdraw(uint256 _tokenId) external {
        require(champions[msg.sender] == _tokenId, "not owner of token");

        // veDEGContract.updateNFTMultiplier(msg.sender, 10);
        degisNFT.safeTransferFrom(address(this), msg.sender, _tokenId);
        champions[msg.sender] = 0;

        // Unboost
        veDEG.unBoostVeDEG(msg.sender);

        emit championWithdrawn(_tokenId, msg.sender);
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
    ) external override returns (bytes4) {
        emit championReceived(operator, from, tokenId, data);
        return this.onERC721Received.selector;
    }
}
