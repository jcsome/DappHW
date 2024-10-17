// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFT/NFTMarket.sol";
import "../src/HookERC20/ExtendERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../src/NFT/BaseERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../src/IERC20.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    ERC20WithCallback public token;
    ERC721 public nft;
    address public seller;
    address public buyer;

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Purchased(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    function setUp() public {
        token = new ERC20WithCallback();
        nft = new ERC721("nft", "N", "");
        market = new NFTMarket(IERC721(address(nft)), IERC20(address(token)));

        seller = address(1);
        buyer = address(2);

        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");

        // 给买家铸造一些代币
        deal(address(token), buyer, 10000 ether);

        // 给卖家铸造一个 NFT
        nft.mint(seller, 1);

        // 卖家批准市场合约转移他们的 NFT
        vm.startPrank(seller);
        nft.setApprovalForAll(address(market), true);
        vm.stopPrank();

        // 买家批准市场合约使用他们的代币
        vm.startPrank(buyer);
        token.approve(address(market), 10000 ether);
        vm.stopPrank();
    }

    function testListNFTSuccess() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;

        vm.startPrank(seller);
        vm.expectEmit(true, true, true, true);
        emit Listed(tokenId, seller, price);

        market.list(tokenId, price);

        // 检查上架信息
        (address listedSeller, uint256 listedPrice) = market.listings(tokenId);
        assertEq(listedSeller, seller);
        assertEq(listedPrice, price);

        vm.stopPrank();
    }

    function testListNFTNotOwner() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;

        vm.startPrank(buyer);
        vm.expectRevert("You are not the owner of this NFT");
        market.list(tokenId, price);
        vm.stopPrank();
    }

    function testListNFTZeroPrice() public {
        uint256 tokenId = 1;

        vm.startPrank(seller);
        vm.expectRevert("Price must be greater than 0");
        market.list(tokenId, 0);
        vm.stopPrank();
    }

    function testBuyNFTSuccess() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;

        // 卖家上架 NFT
        vm.startPrank(seller);
        market.list(tokenId, price);
        vm.stopPrank();

        // 买家购买 NFT
        vm.startPrank(buyer);
        vm.expectEmit(true, true, false, true);
        emit Purchased(tokenId, buyer, seller, price);

        market.buyNFT(tokenId, price);
        vm.stopPrank();

        // 检查所有权转移
        assertEq(nft.ownerOf(tokenId), buyer);
    }

    function testBuyNFTNotEnoughAmount() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;

        // 卖家上架 NFT
        vm.startPrank(seller);
        market.list(tokenId, price);
        vm.stopPrank();

        // 买家尝试支付不足的金额
        vm.startPrank(buyer);
        vm.expectRevert("nft price not equal to amount");
        market.buyNFT(tokenId, 50 ether);
        vm.stopPrank();
    }

    function testBuyNFTOverpay() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;

        // 卖家上架 NFT
        vm.startPrank(seller);
        market.list(tokenId, price);
        vm.stopPrank();

        // 买家尝试支付超额的金额
        vm.startPrank(buyer);
        vm.expectRevert("nft price not equal to amount");
        market.buyNFT(tokenId, 150 ether);
        vm.stopPrank();
    }

    function testBuyNFTAlreadySold() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;

        // 卖家上架 NFT
        vm.startPrank(seller);
        market.list(tokenId, price);
        vm.stopPrank();

        // 买家购买 NFT
        vm.startPrank(buyer);
        market.buyNFT(tokenId, price);
        vm.stopPrank();

        // 另一个买家尝试购买同一 NFT
        address anotherBuyer = address(3);
        deal(address(token), anotherBuyer, 10000 ether);
        vm.startPrank(anotherBuyer);
        token.approve(address(market), 10000 ether);
        vm.expectRevert("ERC721: transfer caller is not owner nor approved");
        market.buyNFT(tokenId, price);
        vm.stopPrank();
    }

    function testBuyOwnNFT() public {
        uint256 tokenId = 1;
        uint256 price = 100 ether;

        // 卖家上架 NFT
        vm.startPrank(seller);
        market.list(tokenId, price);
        vm.stopPrank();

        // 卖家尝试购买自己的 NFT
        vm.startPrank(seller);
        vm.expectRevert("You are the nft owner");
        market.buyNFT(tokenId, price);
        vm.stopPrank();
    }

    function testFuzzListingAndBuying(uint256 price) public {
        vm.assume(price >= 0.01 ether && price <= 10000 ether);

        uint256 tokenId = nft.mint(seller, 2);

        // 随机买家地址
        address randomBuyer = vm.addr(uint256(keccak256(abi.encode(price))));

        // 给买家铸造代币
        deal(address(token), randomBuyer, 20000 ether);

        // 卖家批准市场合约转移 NFT
        vm.startPrank(seller);
        nft.approve(address(market), tokenId);
        market.list(tokenId, price);
        vm.stopPrank();

        // 买家批准代币
        vm.startPrank(randomBuyer);
        token.approve(address(market), 20000 ether);
        vm.stopPrank();

        // 买家购买 NFT
        vm.startPrank(randomBuyer);
        market.buyNFT(tokenId, price);
        vm.stopPrank();

        // 检查所有权
        assertEq(nft.ownerOf(tokenId), randomBuyer);
    }

    function invariantNoTokenBalanceInMarket() public view{
        // 市场合约的代币余额应始终为零
        assertEq(token.balanceOf(address(market)), 0);
    }
}
