// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceManager is Ownable {
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;
    uint256 public giftPrice;
    AggregatorV3Interface public shibPriceFeed;

    constructor(address _shibPriceFeed) Ownable(msg.sender) {
        shibPriceFeed = AggregatorV3Interface(_shibPriceFeed);
    }

    function getLatestTokenPrice(address _token) external view returns (int256) {
        AggregatorV3Interface priceFeed = tokenPriceFeeds[_token];
        require(address(priceFeed) != address(0), "Price feed not set");
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    function updatePriceFeed(address _token, address _feedAddress) external onlyOwner {
        tokenPriceFeeds[_token] = AggregatorV3Interface(_feedAddress);
    }

    function setGiftPrice(uint256 _price) external onlyOwner {
        giftPrice = _price;
    }

    function getLatestShibUsdcPrice() public view returns (int256) {
        (, int256 price, , , ) = shibPriceFeed.latestRoundData();
        return price;
    }
}
