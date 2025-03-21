pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NftMarket is ERC721, Ownable, ReentrancyGuard {
    uint private nextTokenId = 1;

    mapping(uint => string) private tokens; // метаданные
    mapping(uint => uint) private prices;

    event TokenMinted(
        address indexed _to,
        uint indexed tokenId,
        string tokenURI,
        uint price
    );
    event TokenPurchased(
        address indexed buyer,
        uint indexed tokenId,
        address indexed seller,
        uint price
    );
    event TokenPriceUpdated(uint indexed tokenId, uint newPrice);

    constructor() ERC721("MyNFT", "MNFT") Ownable(msg.sender) {}

    function getTokenPrice(uint _tokenId) external view returns (uint) {
        return prices[_tokenId];
    }

    function setPrice(uint _tokenId, uint _price) public onlyOwner {
        prices[_tokenId] = _price;
        emit TokenPriceUpdated(_tokenId, _price);
    }

    function getTokenMetadata(
        uint _tokenId
    ) external view returns (string memory) {
        return tokens[_tokenId];
    }

    function mint(
        address _to,
        string memory _tokenURI,
        uint _price
    ) public onlyOwner {
        _safeMint(_to, nextTokenId);
        tokens[nextTokenId] = _tokenURI;
        prices[nextTokenId] = _price;

        emit TokenMinted(_to, nextTokenId, _tokenURI, _price);

        nextTokenId++;
    }

    function buy(uint _tokenId, bool keepForSale) public payable nonReentrant {
        address currentOwner = ownerOf(_tokenId);
        uint tokenPrice = prices[_tokenId];

        require(tokenPrice > 0, "Token not for sale");
        require(msg.value >= tokenPrice, "Insufficient funds");
        require(currentOwner != msg.sender, "You cannot buy your own token");

        _transfer(currentOwner, msg.sender, _tokenId);

        (bool success, ) = payable(currentOwner).call{value: tokenPrice}("");
        require(success, "Payment to seller failed");

        if (!keepForSale) {
            prices[_tokenId] = 0;
        }

        uint excessAmount = msg.value - tokenPrice;
        if (excessAmount > 0) {
            (bool refundSuccess, ) = payable(msg.sender).call{
                value: excessAmount
            }("");
            require(refundSuccess, "Refund failed");
        }

        emit TokenPurchased(msg.sender, _tokenId, currentOwner, tokenPrice);
    }

    function withdraw() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdraw failed");
    }
}
