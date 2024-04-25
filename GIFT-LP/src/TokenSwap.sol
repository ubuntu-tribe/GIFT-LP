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
    
    //mapping swappable tokens
    mapping(address => bool) public swappableTokens;
    //mapping premium rates
    mapping(address => uint256) public premiumRates;

    LiquidityPool public liquidityPool;
    PriceManager public priceManager;
    Whitelist public whitelist;
    address public premiumWallet; //state variable to store the premium wallet 


    event TokensSwapped(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);
    event PremiumRateUpdated(address indexed account, uint256 newRate);

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
    function setPremiumWallet(address _newPremiumWallet) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can set admin wallet");
        premiumWallet = _newPremiumWallet;
    }

    // Function for setting premium per address
    function setPremiumRate(address _address, uint256 _rate) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can set premium rates");
        require(_rate <= 5, "Rate must be 5% or less");
        premiumRates[_address] = _rate;
        emit PremiumRateUpdated(_address, _rate);
    }
    
    // Function for updating premium
    function updatePremiumRate(address _address, uint256 _newRate) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Only admin can update premium rates");
        require(_newRate <= 5, "Rate must be 5% or less");
        premiumRates[_address] = _newRate;
        emit PremiumRateUpdated(_address, _newRate);
    }

    function swapTokens(address _token, uint256 _amountIn, address _recipient) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(swappableTokens[_token], "Token not swappable");

        IERC20(_token).safeTransferFrom(msg.sender, address(liquidityPool), _amountIn);
    
        //main swap calculations
        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = (_amountIn * 1e18) / giftPrice;

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0 ? 5 : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountOut * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountOut by subtracting the fee
        uint256 finalAmountOut = amountOut - feeAmount;

        // Check if there is enough liquidity before removing
        require(liquidityPool.liquidity(address(liquidityPool.giftToken())) >= finalAmountOut + feeAmount, "Insufficient liquidity");

        // Remove liquidity from the pool
        liquidityPool.removeLiquidity(address(liquidityPool.giftToken()), finalAmountOut + feeAmount);

        // Transfer the GIFT tokens from the liquidity pool to the TokenSwap contract
        IERC20(liquidityPool.giftToken()).safeTransfer(address(this), finalAmountOut + feeAmount);

        // Transfer the final amount to the recipient
        IERC20(liquidityPool.giftToken()).safeTransfer(_recipient, finalAmountOut);

        // Send the fee to the premium wallet
        IERC20(liquidityPool.giftToken()).safeTransfer(premiumWallet, feeAmount);

        emit TokensSwapped(msg.sender, _token, liquidityPool.giftToken(), _amountIn, finalAmountOut);
    }

    function swapGiftToOtherTokens(address _token, uint256 _amountOut, address _recipient) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");
        require(swappableTokens[_token], "Token not swappable");

        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountIn = (_amountOut * 1e18) / giftPrice;

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0 ? 5 : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountIn * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountIn by adding the fee
        uint256 finalAmountIn = amountIn + feeAmount;

        // Transfer the GIFT tokens from the user to the TokenSwap contract
        IERC20(liquidityPool.giftToken()).safeTransferFrom(msg.sender, address(this), finalAmountIn);

        // Check if there is enough liquidity before removing
        require(IERC20(_token).balanceOf(address(liquidityPool)) >= _amountOut, "Insufficient liquidity");

        // Remove liquidity from the pool
        liquidityPool.removeLiquidity(_token, _amountOut);

        // Transfer the swapped tokens from the liquidity pool to the TokenSwap contract
        IERC20(_token).safeTransfer(address(this), _amountOut);

        // Transfer the swapped tokens to the recipient
        IERC20(_token).safeTransfer(_recipient, _amountOut);

        // Transfer the GIFT tokens from the TokenSwap contract to the liquidity pool
        IERC20(liquidityPool.giftToken()).safeTransfer(address(liquidityPool), amountIn);

        // Send the fee to the premium wallet
        IERC20(liquidityPool.giftToken()).safeTransfer(premiumWallet, feeAmount);

        emit TokensSwapped(msg.sender, liquidityPool.giftToken(), _token, finalAmountIn, _amountOut);
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

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0 ? 5 : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountOut * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountOut by subtracting the fee
        uint256 finalAmountOut = amountOut - feeAmount;

        // Check if there is enough liquidity before removing
        require(liquidityPool.liquidity(address(liquidityPool.giftToken())) >= finalAmountOut + feeAmount, "Insufficient liquidity");

        // Remove liquidity from the pool
        liquidityPool.removeLiquidity(address(liquidityPool.giftToken()), finalAmountOut + feeAmount);

        // Transfer the GIFT tokens from the liquidity pool to the TokenSwap contract
        IERC20(liquidityPool.giftToken()).safeTransfer(address(this), finalAmountOut + feeAmount);

        // Transfer the final amount to the recipient
        IERC20(liquidityPool.giftToken()).safeTransfer(_recipient, finalAmountOut);

        // Send the fee to the premium wallet
        IERC20(liquidityPool.giftToken()).safeTransfer(premiumWallet, feeAmount);


        emit TokensSwapped(msg.sender,_tokenIn, liquidityPool.giftToken(), _amountIn, finalAmountOut);
    }


    
    function swapGift(uint256 _amountIn, address _recipient) external nonReentrant {
        require(whitelist.isWhitelisted(msg.sender), "Not whitelisted");

        IERC20(liquidityPool.giftToken()).safeTransferFrom(msg.sender, address(liquidityPool), _amountIn);
    
        uint256 giftPrice = priceManager.giftPrice();
        uint256 amountOut = (_amountIn * giftPrice) / 1e18;

        // Determine the fee percentage
        uint256 feePercentage = premiumRates[msg.sender] == 0 ? 5 : premiumRates[msg.sender]; // Default to 5% if no specific rate is set
        uint256 feeAmount = (amountOut * feePercentage) / 100; // Calculate the fee amount

        // Adjust the amountOut by subtracting the fee
        uint256 finalAmountOut = amountOut - feeAmount;

        // Check if there is enough liquidity before removing
        require(IERC20(liquidityPool.usdcToken()).balanceOf(address(liquidityPool)) >= finalAmountOut + feeAmount, "Insufficient USDC liquidity");

        // Remove USDC liquidity from the pool
        liquidityPool.removeLiquidity(liquidityPool.usdcToken(), finalAmountOut + feeAmount);

        // Transfer the USDC tokens from the liquidity pool to the TokenSwap contract
        IERC20(liquidityPool.usdcToken()).safeTransfer(address(this), finalAmountOut + feeAmount);

        // Transfer the final amount of USDC to the recipient
        IERC20(liquidityPool.usdcToken()).safeTransfer(_recipient, finalAmountOut);

        // Send the fee to the premium wallet
        IERC20(liquidityPool.usdcToken()).safeTransfer(premiumWallet, feeAmount);

        emit TokensSwapped(msg.sender, liquidityPool.giftToken(), liquidityPool.usdcToken(), _amountIn, finalAmountOut);
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
    // Function to update the admin wallet address. Restricted to the current admin.

}
