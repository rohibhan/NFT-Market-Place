// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "hardhat/console.sol";


interface IGameGems {
    function upgradeNFt(address _to) external;
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function isApprovedForAll(address account, address operator) external returns(bool) ;
    function balanceOf(address account, uint256 id) external returns(uint);
}

contract NFT_Market is ERC1155Holder, ERC721Holder {
    using Counters for Counters.Counter;
    
    Counters.Counter private _tokenIds;

    uint immutable MARKUP_PRCNT;

    IERC20 immutable X20;
    IGameGems immutable Gems;

    struct NftItem {
        address nftcontract;
        uint tokenId;
        address seller; 
        Status status;  
        uint price;
    }

    enum Status {
        OPEN,
        SOLD
    }

    mapping(uint => NftItem) public idtoItem;

    event NewItem(address indexed contractAddress, uint indexed tokenId, address indexed seller,uint price, uint item);

    event ItemSold(uint indexed itemId, address indexed buyer);

    // event NftUpgrade();

    constructor(uint _markup_percentage,address _currency_address, address _gems_address) {
            MARKUP_PRCNT = _markup_percentage;
            X20 = IERC20(_currency_address);
            Gems = IGameGems(_gems_address);
    }

    function sell_nft(address nftAddress, uint256 tokenId, uint price) external {
        //TODO: check if nft is approved, from ERC721
        //require
        require(
             IERC721(nftAddress).getApproved(tokenId) == address(this),
            "Token Id is Not Approved"
        );

        uint256 newItemId = _tokenIds.current();

        idtoItem[newItemId] = NftItem(nftAddress, tokenId, msg.sender,Status.OPEN, price);

        _tokenIds.increment();
        IERC721(nftAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit NewItem(nftAddress, tokenId,msg.sender , price,newItemId );

    }

    function buy_nft(uint itemId) external {
        NftItem memory _nftitem = idtoItem[itemId];
        /* 
        Check if price of item is approved on ERC20 contract for transfer.
        Price to be checked should be item price + 5% markup.
        */
        require(_nftitem.nftcontract != address(0), "item_does_not_exist");
        require( _nftitem.status == Status.OPEN, "item_not_for_sale");

        uint sellling_price = _nftitem.price +  Math.mulDiv(_nftitem.price, MARKUP_PRCNT, 100)  ;
      
        require(X20.allowance(msg.sender,address(this)) >= sellling_price   , "price_not_correct"  );

        //transfer the amount to owner 
        X20.transferFrom(msg.sender,_nftitem.seller, _nftitem.price);
        X20.transferFrom(msg.sender,address(this),Math.mulDiv(_nftitem.price, MARKUP_PRCNT, 100)  );  

        idtoItem[itemId].status = Status.SOLD;

        IERC721(_nftitem.nftcontract).transferFrom(
            address(this),
            msg.sender,
            _nftitem.tokenId
        );

        emit ItemSold(itemId, msg.sender);
    }

    function upgrade_nft(address nftAddress, uint256 tokenId) external {
        require(Gems.isApprovedForAll(msg.sender, address(this)) && Gems.balanceOf(msg.sender,0) >= 1000 , "insufficient_gems" );

        //transfer gems to self
        Gems.safeTransferFrom(msg.sender,address(this), 0, 1000, "");
        Gems.upgradeNFt(msg.sender);

        //burning nft by transfering to self
        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
    }

    function ItemfinalPrice(uint itemId) external view returns(uint sellling_price) {
            sellling_price = idtoItem[itemId].price + Math.mulDiv(idtoItem[itemId].price, MARKUP_PRCNT, 100)  ;
    }



}
