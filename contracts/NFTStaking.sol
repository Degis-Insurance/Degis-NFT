// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IDegisNFT} from "./interfaces/IDegisNFT.sol";
import {IVeDEG} from "./interfaces/IVeDEG.sol";

contract NFTStaking is Ownable, IERC721Receiver {
    // ---------------------------------------------------------------------------------------- //
    // ************************************* Variables **************************************** //
    // ---------------------------------------------------------------------------------------- //

    IDegisNFT public degisNFT;
    IVeDEG public veDEG;

    mapping(address => uint256) public userStaked;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //

    event championReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );

    event Stake(address user, uint256 tokenId, uint256 boostType);
    event Unstake(address user, uint256 tokenId);

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    constructor(address _degisNFT, address _veDEG) {
        degisNFT = IDegisNFT(_degisNFT);
        veDEG = IVeDEG(_veDEG);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set degis nft contract
     *
     * @param _degisNFT Degis nft address
     */
    function setDegisNFTContract(address _degisNFT) external onlyOwner {
        degisNFT = IDegisNFT(_degisNFT);
    }

    /**
     * @notice Set veDEG contract
     *
     * @param _veDEG VeDEG address
     */
    function setVeDEG(address _veDEG) external onlyOwner {
        veDEG = IVeDEG(_veDEG);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Main Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Stake NFT
     *
     * @param _tokenId Token id to stake
     */
    function stake(uint256 _tokenId) external {
        require(degisNFT.ownerOf(_tokenId) == msg.sender, "not owner of token");
        require(_tokenId != 0, "tokenId cannot be 0");

        require(userStaked[msg.sender] == 0, "already staked");

        degisNFT.approve(address(this), _tokenId);

        degisNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        userStaked[msg.sender] = _tokenId;

        // If token id > 99 normal boost
        // If token id <= 99 rare boost
        uint256 boostType = _tokenId > 99 ? 1 : 2;
        veDEG.boostVeDEG(msg.sender, boostType);

        emit Stake(msg.sender, _tokenId, boostType);
    }

    /**
     * @notice Withdraw NFT
     *
     * @param _tokenId Token id to withdraw
     */
    function withdraw(uint256 _tokenId) external {
        require(userStaked[msg.sender] == _tokenId, "not owner of token");

        degisNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        // Delete the record
        userStaked[msg.sender] = 0;

        // Unboost veDEG
        veDEG.unBoostVeDEG(msg.sender);

        emit Unstake(msg.sender, _tokenId);
    }

    /**
     * @notice Selector for receiving ERC721 tokens
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
