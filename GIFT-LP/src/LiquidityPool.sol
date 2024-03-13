// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PriceManager.sol";
import "./Whitelist.sol";

contract LiquidityPool is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Premium {
        uint256 percentage;
        address permissionAddress;
    }

    address public giftToken;
    address public usdcToken;
    address public usdtToken;
    address[] public otherSwappableTokens;
    mapping(address => uint256) public liquidity;
    uint256 public giftPrice;
    Premium[] public premiums;

    bytes32 public constant LIQUIDITY_PROVIDER_ROLE = keccak256("LIQUIDITY_PROVIDER_ROLE");
    bytes32 public constant PRICE_SETTER_ROLE = keccak256("PRICE_SETTER_ROLE");
    bytes32 public constant PREMIUM_MANAGER_ROLE = keccak256("PREMIUM_MANAGER_ROLE");

    PriceManager public priceManager;
    Whitelist public whitelist;

    event LiquidityAdded(address indexed provider, address indexed token, uint256 amount);
    event LiquidityRemoved(address indexed provider, address indexed token, uint256 amount);
    event GiftPriceChanged(uint256 newPrice);
    event StablecoinsWithdrawn(uint256 amount);
    event LiquidityThresholdAlert(address indexed token, uint256 threshold);

    constructor(
        address _giftToken,
        address _usdcToken,
        address _usdtToken,
        address _priceManager,
        address _whitelist
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        giftToken = _giftToken;
        usdcToken = _usdcToken;
        usdtToken = _usdtToken;
        priceManager = PriceManager(_priceManager);
        whitelist = Whitelist(_whitelist);
    }

    function addLiquidity(address _token, uint256 _amount) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender), "Not a liquidity provider");

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        liquidity[_token] += _amount;

        emit LiquidityAdded(msg.sender, _token, _amount);
    }

    function removeLiquidity(address _token, uint256 _amount) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender), "Not a liquidity provider");
        require(liquidity[_token] >= _amount, "Insufficient liquidity");

        IERC20(_token).safeTransfer(msg.sender, _amount);
        liquidity[_token] -= _amount;

        emit LiquidityRemoved(msg.sender, _token, _amount);
    }

    function setGiftPrice(uint256 _price) external {
        require(hasRole(PRICE_SETTER_ROLE, msg.sender), "Not a price setter");
        giftPrice = _price;
        emit GiftPriceChanged(_price);
    }

    function withdrawStablecoins(uint256 _amount) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        require(liquidity[usdcToken] + liquidity[usdtToken] >= _amount, "Insufficient stablecoins");

        uint256 usdcAmount = _amount / 2;
        uint256 usdtAmount = _amount - usdcAmount;

        IERC20(usdcToken).safeTransfer(msg.sender, usdcAmount);
        IERC20(usdtToken).safeTransfer(msg.sender, usdtAmount);

        liquidity[usdcToken] -= usdcAmount;
        liquidity[usdtToken] -= usdtAmount;

        emit StablecoinsWithdrawn(_amount);
    }

    function checkLiquidityThreshold(address _token, uint256 _threshold) external view {
        if (liquidity[_token] < _threshold) {
            emit LiquidityThresholdAlert(_token, _threshold);
        }
    }
}