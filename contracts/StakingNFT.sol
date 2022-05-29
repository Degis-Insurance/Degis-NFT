// SPDX-License-Identifier: UNLICENSED
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

contract NFTStaking is Ownable, IERC721Receiver {

    IDegisNFT public degisNFTContract;
    IveDEG public veDEGContract;

    mapping(address => uint256) public champions;

    event championReceived(address operator,address from,uint256 tokenId, bytes data);
    event championWithdrawn(uint256 tokenId, address to);

    function setDegisNFTContract (address _degisNFT) external onlyOwner {
        degisNFTContract = IDegisNFT(_degisNFT);
    }

    function setIveDEG (address _veDeg) external onlyOwner {
        veDEGContract = IveDEG(_veDeg);
    }

    function onERC721Received(address operator,address from,uint256 tokenId, bytes calldata data) external override returns(bytes4){
        return this.onERC721Received.selector;
        emit championReceived(operator, from, tokenId, data);
    }

    function stakeChampion(uint256 _tokenId) external {
        require(degisNFTContract.ownerOf(_tokenId) != address(0), "token not owned");
        require(degisNFTContract.ownerOf(_tokenId) == msg.sender, "not owner of token");
        require(_tokenId != 0, "tokenId cannot be 0");
        // uint256 _multiplier = _tokenId <= 99 ? 15 : 12;
        // veDEGContract.updateNFTMultiplier(msg.sender,_multiplier);
        degisNFTContract.safeTransferFrom(msg.sender, address(this), _tokenId);
        champions[msg.sender] = _tokenId;
    }

    function withdrawChampion(uint256 _tokenId) external {
        require(champions[msg.sender] == _tokenId, "not owner of token");
        // veDEGContract.updateNFTMultiplier(msg.sender, 10);
        degisNFTContract.safeTransferFrom(address(this), msg.sender, _tokenId);
        champions[msg.sender] = 0;
        emit championWithdrawn(_tokenId, msg.sender);
    }
}