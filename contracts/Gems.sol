// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract GemGame is ERC1155,Ownable {
    uint256 public constant GEMS = 0;
    uint private tokenCounter = 1 ;


    mapping(uint => uint) public tokenToUnlockTime;

    address MarketMinter;

    constructor() ERC1155("") {
        _transferOwnership(msg.sender);
        _mint(msg.sender, GEMS, 10000, "");
    }

    function setMarketMinter(address _marketContract) onlyOwner external {
        MarketMinter = _marketContract;
    }
 
    function upgradeNFt(address _to) external {
        require(msg.sender == MarketMinter, "only_market_can_mint");
         _mint(_to, tokenCounter, 1, "");

         //set cooldown period to 14 days
         tokenToUnlockTime[tokenCounter] = (14*86400) + block.timestamp;
         
         tokenCounter += 1;
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual override {
        //check if cooldown is over
        for(uint i=0;i<ids.length; i++)
           {
               require(tokenToUnlockTime[ids[i]] < block.timestamp , "token_cant_be_transferred_before_cooldown" );
           }   

        super._beforeTokenTransfer(operator,from,to,ids,amounts,data);      

    }

}