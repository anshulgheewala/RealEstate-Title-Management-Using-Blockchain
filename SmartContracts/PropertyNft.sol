// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Import ERC20 interface

contract RealEstateNFT is ERC721URIStorage, Ownable {
    IERC20 public realEstateToken; // Reference to the RCoin contract
    uint256 public nextPropertyId;

    struct Property {
        uint256 id;
        address owner;
        uint256 price;
        bool isListed;
        string location;
        string imageURL;
        string legalDocsHash;
    }

    mapping(uint256 => Property) public properties;

    constructor(address _tokenAddress) ERC721("RealEstateNFT", "Property") Ownable(msg.sender){
        realEstateToken = IERC20(_tokenAddress); // Store RCoin token address
    }

    function mintProperty(
        address to,
        string memory tokenURI,
        uint256 price,
        string memory location,
        string memory imageURL,
        string memory legalDocsHash
    ) external onlyOwner {
        uint256 propertyId = nextPropertyId;
        _mint(to, propertyId);
        _setTokenURI(propertyId, tokenURI);

        properties[propertyId] = Property(
            propertyId,
            to,
            price,
            false,
            location,
            imageURL,
            legalDocsHash
        );

        nextPropertyId++;
    }

    function listProperty(uint256 propertyId, uint256 price) external {
        require(ownerOf(propertyId) == msg.sender, "Not the owner");
        properties[propertyId].isListed = true;
        properties[propertyId].price = price;
    }

    function transferProperty(address newOwner, uint256 propertyId) external {
        require(ownerOf(propertyId) == msg.sender, "Not the owner");
        require(properties[propertyId].isListed, "Property not listed for sale");

        uint256 price = properties[propertyId].price;

        // Ensure buyer has enough RCoin
        require(realEstateToken.balanceOf(newOwner) >= price, "Insufficient RCoin balance");
        
        // Transfer RCoin from buyer to seller
        require(realEstateToken.transferFrom(newOwner, msg.sender, price), "RCoin transfer failed");

        // Transfer NFT ownership
        _transfer(msg.sender, newOwner, propertyId);
        properties[propertyId].owner = newOwner;
        properties[propertyId].isListed = false;
    }

    function updatePropertyDetails(
        uint256 propertyId,
        string memory newLocation,
        string memory newImageURL,
        string memory newLegalDocsHash
    ) external {
        require(ownerOf(propertyId) == msg.sender, "Not the owner");

        Property storage property = properties[propertyId];
        property.location = newLocation;
        property.imageURL = newImageURL;
        property.legalDocsHash = newLegalDocsHash;
    }

    function getPropertyDetails(uint256 propertyId) external view returns (Property memory) {
        return properties[propertyId];
    }
    
    function getAllListedProperties() external view returns (uint256[] memory) {
        uint256 total = nextPropertyId;
        uint256 count = 0;

        for (uint256 i = 0; i < total; i++) {
            if (properties[i].isListed) {
                count++;
            }
        }

        uint256[] memory listedPropertyIds = new uint256[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < total; i++) {
            if (properties[i].isListed) {
                listedPropertyIds[index] = properties[i].id;
                index++;
            }
        }

        return listedPropertyIds;
    }

    function buyProperty(uint256 propertyId) external payable {
    Property storage property = properties[propertyId];
    require(property.isListed, "Property is not listed for sale");
    require(msg.value >= property.price, "Insufficient funds sent");
    
    address previousOwner = ownerOf(propertyId);
    
    // Transfer funds to the seller
    payable(previousOwner).transfer(msg.value);
    
    // Transfer ownership of NFT
    _transfer(previousOwner, msg.sender, propertyId);
    
    // Update property details
    property.owner = msg.sender;
    property.isListed = false;

    // Emit event
    emit PropertySold(propertyId, previousOwner, msg.sender, msg.value);
}

event PropertySold(uint256 propertyId, address indexed seller, address indexed buyer, uint256 price);

}
