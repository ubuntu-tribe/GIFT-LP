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

    /**
    * @dev Make sure that the `giftPrice` variable in the `PriceManager` contract is updated
    * correctly to reflect the price of GIFT tokens in cents with 18 decimal places.
    * For example, if the price is 0.072 cents per milligram, the `giftPrice` should be
    * set to `72000000000000000` (0.072 * 1e18).
    */

    function swapTokens(address _token, uint256 _amountIn, address _recipient) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(swappableTokens[_token], "Token not swappable");

        IERC20(_token).safeTransferFrom(msg.sender, address(liquidityPool), _amountIn);

        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = (_amountIn * 1e18) / giftPrice;
        // Check if there is enough liquidity before removing
        require(liquidityPool.liquidity(address(liquidityPool.giftToken())) >= amountOut, "Insufficient liquidity");


        liquidityPool.removeLiquidity(address(liquidityPool.giftToken()), amountOut);
        IERC20(liquidityPool.giftToken()).safeTransfer(_recipient, amountOut);

        emit TokensSwapped(msg.sender, _token, liquidityPool.giftToken(), _amountIn, amountOut);
    }

    function swapGiftToOtherTokens(address _token, uint256 _amountOut) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(swappableTokens[_token], "Token not swappable");

        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountIn = (_amountOut * giftPrice) / 1e18;

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
        uint256 amountOut = (_amountIn * 1e18) / giftPrice;

        // Check if there is enough liquidity before removing
        require(liquidityPool.liquidity(address(liquidityPool.giftToken())) >= amountOut, "Insufficient liquidity");

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

    // Function to update the PriceManager contract address. Restricted to admin.
    function setPriceManager(address _priceManager) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        priceManager = PriceManager(_priceManager);
    }

    // Function to update the Whitelist contract address. Restricted to admin.
    function setWhitelist(address _whitelist) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        whitelist = Whitelist(_whitelist);
    }

    // Function to transfer the admin role to a new address. Restricted to the current admin.
    function transferAdminRole(address newAdmin) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can transfer admin role");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
