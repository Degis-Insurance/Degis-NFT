// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import {IDegisNFT} from "./interfaces/IDegisNFT.sol";
import {IVeDEG} from "./interfaces/IVeDEG.sol";

contract NFTStaking is Ownable, IERC721Receiver {
    IDegisNFT public degisNFT;
    IVeDEG public veDEG;

    mapping(address => uint256) public champions;

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

    /**
     * @notice Stake NFT
     *
     * @param _tokenId Token id to stake
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
     * @notice Withdraw NFT
     *
     * @param _tokenId Token id to withdraw
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
}
