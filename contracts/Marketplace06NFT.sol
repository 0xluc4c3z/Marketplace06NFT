// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Marketplace06NFT
/// @author Lucacez
/// @notice Marketplace based on the nft collection Germany06NFT.

error NftMarketplace__TokenIdExists(uint256 tokenId);
error NftMarketplace__NotListed(uint256 tokenId);
error NftMarketplace__NowOwner();
error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__PriceNotMet(uint256 tokenId, uint256 price);
error NftMarketplace__NoProceeds();
error NftMarketplace__TransferFailed();

contract Marketplace06NFT is ReentrancyGuard {
    
    struct MarketItem {
        address seller;
        uint256 price;
    }

    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCancelled(
        address indexed seller,
        uint256 indexed tokenId
    );

    event ItemBought(
        address indexed buyer,
        uint256 indexed tokenId,
        uint256 price
    );

    mapping(uint256 => MarketItem) private marketItems;
    mapping(address => uint256) private addressProceeds;

    IERC721 nftContract = IERC721(0x6B5eA1B2ced8541c8082dFF8865c4A8141c54826);

    //si el token tiene un seteado un precio mayor a 0 revierte, quiere decir que existe
    modifier notListed(uint256 tokenId) {
        MarketItem memory item = marketItems[tokenId];
        if (item.price > 0) {
            revert NftMarketplace__TokenIdExists(tokenId);
        }
        _;
    }

    //si el token tiene un precio menor o igual a 0 revierte, quiere decir que no existe
    modifier isListed(uint256 tokenId) {
        MarketItem memory item = marketItems[tokenId];
        if (item.price <= 0) {
            revert NftMarketplace__NotListed(tokenId);
        }
        _;
    }

    //si la direccion del duenio es distinta a la del owner revierte 
    modifier isOwner(
        uint256 tokenId,
        address spender
    ) {
        address owner = nftContract.ownerOf(tokenId);
        if (spender != owner) {
            revert NftMarketplace__NowOwner();
        }
        _;
    }

    function listItem(
        uint256 tokenId,
        uint256 price
    ) external notListed(tokenId) isOwner(tokenId, msg.sender) {
        if (price <= 0) {
            revert NftMarketplace__PriceMustBeAboveZero();
        }
        if (nftContract.getApproved(tokenId) != address(this)) {
            revert NftMarketplace__NotApprovedForMarketplace();
        }
        marketItems[tokenId] = MarketItem(msg.sender, price);
        emit ItemListed(msg.sender, tokenId, price);
    }

    function cancelListing(uint256 tokenId)
        external
        isListed(tokenId)
        isOwner(tokenId, msg.sender)
    {
        delete (marketItems[tokenId]);
        emit ItemCancelled(msg.sender, tokenId);
    }

    function buyItem(uint256 tokenId)
        external
        payable
        isListed(tokenId)
        nonReentrant
    {
        MarketItem memory item = marketItems[tokenId];
        if (msg.value < item.price) {
            revert NftMarketplace__PriceNotMet(tokenId, item.price);
        }
        addressProceeds[item.seller] += msg.value;
        delete (marketItems[tokenId]);
        nftContract.safeTransferFrom(item.seller, msg.sender, tokenId);
        emit ItemBought(msg.sender, tokenId, item.price);
    }

    function updateListing(
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isListed(tokenId)
        nonReentrant
        isOwner(tokenId, msg.sender)
    {
        marketItems[tokenId].price = newPrice;
        emit ItemListed(msg.sender, tokenId, newPrice);
    }

    //retirar el saldo almacenado del vendedor
    function withdrawProceeds() external {
        uint256 proceeds = addressProceeds[msg.sender];
        if (proceeds <= 0) {
            revert NftMarketplace__NoProceeds();
        }
        addressProceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) {
            revert NftMarketplace__TransferFailed();
        }
    }

    function getMarketItem(uint256 tokenId)
        external
        view
        returns (MarketItem memory)
    {
        return marketItems[tokenId];
    }

    function getAddressProceeds(address seller) external view returns (uint256) {
        return addressProceeds[seller];
    }
}