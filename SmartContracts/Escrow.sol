// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateMarketplace is Ownable {
    IERC20 public token; // RET Token (ERC-20)
    IERC721 public nft;  // Real Estate NFT (ERC-721)

    struct Property {
        uint256 tokenId;
        address owner;
        uint256 price;
        string imageURL;
        bool isListed;
    }

    mapping(uint256 => Property) public properties; // tokenId → Property
    uint256[] public listedProperties; // List of property token IDs

    event PropertyListed(uint256 indexed tokenId, address indexed owner, uint256 price, string imageURL);
    event PropertySold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    constructor(address _token, address _nft) Ownable(msg.sender){
        token = IERC20(_token);
        nft = IERC721(_nft);
    }

    // List a property for sale
    function listProperty(uint256 tokenId, uint256 price, string memory imageURL) public {
        require(price > 0, "Price must be greater than zero");
        require(nft.ownerOf(tokenId) == msg.sender, "You must own the property");
        require(nft.getApproved(tokenId) == address(this), "Marketplace not approved to transfer this NFT");

        properties[tokenId] = Property({
            tokenId: tokenId,
            owner: msg.sender,
            price: price,
            imageURL: imageURL,
            isListed: true
        });

        listedProperties.push(tokenId);

        emit PropertyListed(tokenId, msg.sender, price, imageURL);
    }

    // Buy a listed property
    function buyProperty(uint256 tokenId) public {
        Property storage property = properties[tokenId];
        require(property.isListed, "Property is not for sale");
        require(token.balanceOf(msg.sender) >= property.price, "Insufficient RET tokens");

        // Transfer RET tokens from buyer to seller
        require(token.transferFrom(msg.sender, property.owner, property.price), "Token transfer failed");

        // Transfer NFT ownership
        nft.safeTransferFrom(property.owner, msg.sender, tokenId);

        // Update property ownership
        property.owner = msg.sender;
        property.isListed = false;

        emit PropertySold(tokenId, msg.sender, property.price);
    }

    // Get all listed properties
    function getListedProperties() public view returns (Property[] memory) {
        uint256 count = listedProperties.length;
        Property[] memory props = new Property[](count);
        for (uint256 i = 0; i < count; i++) {
            props[i] = properties[listedProperties[i]];
        }
        return props;
    }
}
