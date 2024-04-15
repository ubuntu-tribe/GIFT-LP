// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PriceManagerUpgradeable is Initializable, OwnableUpgradeable, AccessControlUpgradeable {
    mapping(address => AggregatorV3Interface) public tokenPriceFeeds;
    uint256 public giftPrice;
    AggregatorV3Interface public shibPriceFeed;


    bytes32 public constant PRICE_SETTER_ROLE = keccak256("PRICE_SETTER_ROLE");

    function initialize(address _shibPriceFeed) public initializer {
        __Ownable_init(msg.sender);
        __AccessControl_init();
        shibPriceFeed = AggregatorV3Interface(_shibPriceFeed);
        _grantRole(PRICE_SETTER_ROLE, msg.sender);
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

    function setGiftPrice(uint256 _price) external {
        require(hasRole(PRICE_SETTER_ROLE, msg.sender) || owner() == msg.sender, "Not authorized to set gift price");
        giftPrice = _price;
    }

    function grantPriceSetterRole(address _account) external onlyOwner {
        _grantRole(PRICE_SETTER_ROLE, _account);
    
    }

    function revokePriceSetterRole(address _account) external onlyOwner {
        _revokeRole(PRICE_SETTER_ROLE, _account);
    
    }

    function getLatestShibUsdcPrice() public view returns (int256) {
        (, int256 price, , , ) = shibPriceFeed.latestRoundData();
        return price;
    }
}
