// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./LiquidityPool.sol";
import "./PriceManager.sol";
import "./Whitelist.sol";

contract TokenSwap is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => bool) public swappableTokens;

    LiquidityPool public liquidityPool;
    PriceManager public priceManager;
    Whitelist public whitelist;

    event TokensSwapped(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);

    constructor(address _liquidityPool, address _priceManager, address _whitelist) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        liquidityPool = LiquidityPool(_liquidityPool);
        priceManager = PriceManager(_priceManager);
        whitelist = Whitelist(_whitelist);
    }

    function swapTokens(address _token, uint256 _amountIn) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(swappableTokens[_token], "Token not swappable");

        IERC20(_token).safeTransferFrom(msg.sender, address(liquidityPool), _amountIn);

        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = (_amountIn * giftPrice) / 1e18;

        liquidityPool.removeLiquidity(address(liquidityPool.giftToken()), amountOut);
        IERC20(liquidityPool.giftToken()).safeTransfer(msg.sender, amountOut);

        emit TokensSwapped(msg.sender, _token, liquidityPool.giftToken(), _amountIn, amountOut);
    }

    function swapGiftToOtherTokens(address _token, uint256 _amountOut) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(swappableTokens[_token], "Token not swappable");

        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountIn = (_amountOut * 1e18) / giftPrice;

        IERC20(liquidityPool.giftToken()).safeTransferFrom(msg.sender, address(liquidityPool), amountIn);
        liquidityPool.addLiquidity(_token, _amountOut);
        IERC20(_token).safeTransfer(msg.sender, _amountOut);

        emit TokensSwapped(msg.sender, liquidityPool.giftToken(), _token, amountIn, _amountOut);
    }

    /**
     * @dev Swaps `_amountIn` of `_tokenIn` to GIFT and sends to `_recipient`.
     * Only callable by whitelisted addresses.
     * `_recipient` is the address to receive GIFT tokens.
     */
    function swapTokensForRecipient(address _tokenIn, uint256 _amountIn, address _recipient) external {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(swappableTokens[_tokenIn], "Token not swappable");
        
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(liquidityPool), _amountIn);

        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = (_amountIn * giftPrice) / 1e18;

        liquidityPool.removeLiquidity(address(liquidityPool.giftToken()), amountOut);
        IERC20(liquidityPool.giftToken()).safeTransfer(_recipient, amountOut);

        emit TokensSwapped(msg.sender, _tokenIn, liquidityPool.giftToken(), _amountIn, amountOut);
    }

    function addSwappableToken(address _token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        swappableTokens[_token] = true;
    }

    function removeSwappableToken(address _token) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        swappableTokens[_token] = false;
    }
}