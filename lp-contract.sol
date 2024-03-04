//lp-contract GIFT
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LiquidityPool is Ownable {
    using SafeMath for uint256;

    IERC20 public giftToken; // Main token (GIFT)
    mapping(address => bool) public whitelistedAddresses;
    mapping(address => uint256) public liquidity;

    uint256 public giftPrice; // Price of GIFT token
    address public usdcToken; // Stablecoin token (e.g., USDC)

    event LiquidityAdded(address indexed user, uint256 amount);
    event LiquidityRemoved(address indexed user, uint256 amount);
    event TokensSwapped(address indexed user, uint256 amountIn, uint256 amountOut);

    constructor(address _giftToken, address _usdcToken) {
        giftToken = IERC20(_giftToken);
        usdcToken = _usdcToken;
    }

    // Set the price of the GIFT token
    function setGiftPrice(uint256 _price) external onlyOwner {
        giftPrice = _price;
    }

    // Add liquidity to the pool
    function addLiquidity(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than zero");
        require(giftToken.transferFrom(msg.sender, address(this), _amount), "Failed to transfer tokens");
        
        liquidity[msg.sender] = liquidity[msg.sender].add(_amount);
        emit LiquidityAdded(msg.sender, _amount);
    }

    // Remove liquidity from the pool
    function removeLiquidity(uint256 _amount) external {
        require(_amount > 0 && _amount <= liquidity[msg.sender], "Invalid amount");
        
        liquidity[msg.sender] = liquidity[msg.sender].sub(_amount);
        require(giftToken.transfer(msg.sender, _amount), "Failed to transfer tokens");
        
        emit LiquidityRemoved(msg.sender, _amount);
    }

    // Swap tokens against GIFT
    function swapTokens(address _token, uint256 _amountIn) external {
        require(whitelistedAddresses[msg.sender], "Address not whitelisted");
        require(_token == usdcToken, "Invalid token");

        uint256 amountOut = _amountIn.mul(giftPrice).div(1e18); // Calculate amount of GIFT tokens
        
        // Transfer GIFT tokens to user
        require(giftToken.transfer(msg.sender, amountOut), "Failed to transfer tokens");

        emit TokensSwapped(msg.sender, _amountIn, amountOut);
    }

    // Add address to whitelist
    function addToWhitelist(address _address) external onlyOwner {
        whitelistedAddresses[_address] = true;
    }

    // Remove address from whitelist
    function removeFromWhitelist(address _address) external onlyOwner {
        whitelistedAddresses[_address] = false;
    }

    // Upgradeability: placeholder function
    function upgradeContract() external onlyOwner {
        // Placeholder function for contract upgradeability
        // (Implementation not provided in this example)
    }
}
