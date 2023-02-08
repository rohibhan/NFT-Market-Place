const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFT Market Place", function () {

  let xcurrency, gemgame, gameitem, nftmarket;

  let seller, buyer;

  before(async () => {

    [seller, buyer] = await ethers.getSigners();

    const XCurrency_factory = await ethers.getContractFactory("XCurrency");
    xcurrency = await XCurrency_factory.deploy(100000);

    const GemGame_factory = await ethers.getContractFactory("GemGame");
    gemgame = await GemGame_factory.deploy();

    const GameItem_factory = await ethers.getContractFactory("GameItem");
    gameitem = await GameItem_factory.deploy();

    const NFT_Market_factory = await ethers.getContractFactory("NFT_Market");
    nftmarket = await NFT_Market_factory.deploy(5, xcurrency.address, gemgame.address);

    //fund the buyer account with gems and erc20 x currency
    let tx = await xcurrency.transfer(buyer.address, 1000);
    tx.wait();

    tx = await gemgame.safeTransferFrom(seller.address, buyer.address, 0, 5000, "0x")
    tx.wait();
    //set Nft market as market minter for upragding nft
    tx = await gemgame.setMarketMinter(nftmarket.address);
    await tx.wait();

  });


  describe("Sell NFT", function () {

    it("User Should be able to sell NFT", async function () {
      let tx = await gameitem.awardItem(seller.address, "test.xyz");
      await tx.wait();

      tx = await gameitem.approve(nftmarket.address, 0);
      await tx.wait();


      tx = await nftmarket.sell_nft(gameitem.address, 0, 100);
      await tx.wait();

      const itemDetails = await nftmarket.idtoItem(0);

      expect(itemDetails.nftcontract).to.equal(gameitem.address);

      //expect(await lock.unlockTime()).to.equal(unlockTime);
    });

    it("Should not able to sell if NFT not approved", async function () {
      let tx = await gameitem.awardItem(seller.address, "test.xyz");
      await tx.wait();

      await expect(nftmarket.sell_nft(gameitem.address, 1, 10)).to.be.revertedWith("Token Id is Not Approved");

    });

  });

  describe("Buy NFT", function () {
      it("Buyer should be able to buy NFT", async function(){

          const itemPrice = await nftmarket.ItemfinalPrice(0);
         

          let tx = await xcurrency.connect(buyer).approve(nftmarket.address, itemPrice);
          await tx.wait();

        tx = await nftmarket.connect(buyer).buy_nft(0);
             await tx.wait()

        const item = await nftmarket.idtoItem(0)

        expect(item.status).to.equal(1);
      

      });
  });


  describe("Upgrade the nft", async () => {

    it("User should be able to upgrade the nft", async () => {

        //approve the 1155 gems
        let tx =  await gemgame.connect(buyer).setApprovalForAll(nftmarket.address, true);
        await tx.wait();
        //approve nft for burning
        tx = await gameitem.connect(buyer).approve(nftmarket.address, 0);
        await tx.wait();

        tx = await nftmarket.connect(buyer).upgrade_nft(gameitem.address,0);
        await tx.wait();

        expect(await gemgame.balanceOf(buyer.address,1)).to.equal(1);
    })

    it("User should not be able to sell before 14 calender days", async () => {

        await expect(gemgame.connect(buyer).safeTransferFrom(buyer.address, seller.address, 1, 1, "0x")).to.be.revertedWith("token_cant_be_transferred_before_cooldown");
    
    })

    it("User should be able to sell after 14 calender days", async () => {
      let currentTime = Date.now();

      const future_time_in_sec= (currentTime/1000) + (14*86400);
      
      await time.increase(14*86400);

     let tx = await gemgame.connect(buyer).safeTransferFrom(buyer.address, seller.address, 1, 1, "0x");
     await tx.wait();


    })

  })


});
