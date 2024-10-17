// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../HookERC20/ExtendERC20.sol";

contract NFTMarket is ITokenReceiver, IERC721Receiver{
    IERC20 public token;  // ERC20 token used for payments
    IERC721 public nft;   // NFT contract

    struct Listing {
        address seller;
        uint256 price;  // Price in ERC20 tokens
    }

    // Mapping of NFT IDs to their listings
    mapping(uint256 => Listing) public listings;

    event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event Purchased(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);

    constructor(IERC721 _nft, IERC20 _token) {
        nft = _nft;
        token = _token;
    }

    // Function for NFT owners to list their NFTs for sale
    function list(uint256 tokenId, uint256 price) external {
        require(nft.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");
        require(price > 0, "Price must be greater than 0");

        // Approve the NFT to the market contract for custody
        nft.approve(address(this), tokenId);

        // Create the listing
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        emit Listed(tokenId, msg.sender, price);
    }

    function buyNFT(uint256 tokenId, uint256 amount) public {
        require(listings[tokenId].price == amount, "nft price not equal to amount");
        require(msg.sender!=listings[tokenId].seller, "You are the nft owner");
        // Transfer the ERC20 tokens to the buyer
        token.transferFrom(msg.sender, listings[tokenId].seller, listings[tokenId].price);
        nft.safeTransferFrom(listings[tokenId].seller, msg.sender, tokenId);
        emit Purchased(tokenId, msg.sender, listings[tokenId].seller, amount);
    }

    // IERC20Receiver implementation to handle token transfer callback
    function tokenReceived(address from, uint256 amount, bytes calldata data) external override {
        require(msg.sender == address(token), "Only ERC20 token transfers accepted");
        uint256 tokenId = abi.decode(data, (uint256));

        Listing memory listing = listings[tokenId];
        require(listing.price == amount, "Incorrect token amount sent");

        // Transfer the NFT to the buyer
        nft.safeTransferFrom(listing.seller, from, tokenId);

        // Transfer the ERC20 tokens to the seller
        token.transferFrom(from, listing.seller, amount);

        // Clear the listing
        delete listings[tokenId];

        emit Purchased(tokenId, from, listing.seller, amount);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
