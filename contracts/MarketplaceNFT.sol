//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract MarketplaceNFT is ReentrancyGuard {

    using Counters for Counters.Counter;

    Counters.Counter s_itemIds;
    Counters.Counter s_itemSolds;
    address s_nft;
    

    struct Listing{
        uint256 itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    constructor(address nft){
        s_nft = nft;
    }

    ERC721 nft_contract = ERC721(s_nft);

    mapping(uint256 => Listing) s_listings;

    function listarJugador(uint256 tokenId, uint256 price) public nonReentrant{
        require(price > 0, "");
         
        s_itemIds.increment();
        uint256 itemId = s_itemIds.current();

        s_listings[itemId] = Listing(itemId, tokenId, payable(msg.sender), payable(address(0)), price, false);
        
        IERC721(nft_contract).transferFrom(msg.sender, address(this), tokenId);
    }


    function ficharJugador(uint itemId) public payable nonReentrant{

        uint price = s_listings[itemId].price;
        uint tokenId = s_listings[itemId].tokenId;

        require(msg.value >= price, "");
        s_listings[itemId].seller.transfer(msg.value);

        IERC721(nft_contract).transferFrom(address(this), msg.sender, tokenId);
        s_listings[itemId].owner = payable(msg.sender);
        s_listings[itemId].sold = true;
        s_itemSolds.increment();
    }

    function cancel(uint tokenId) public{

        require(msg.sender == s_listings[tokenId].seller);
        require(s_listings[tokenId].sold == false);

        IERC721(nft_contract).transferFrom(address(this), msg.sender, tokenId);
    }

    

}
