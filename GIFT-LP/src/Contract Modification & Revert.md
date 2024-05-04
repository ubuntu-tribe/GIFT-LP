## Contract Modification & Revert : Restricting Accepted Tokens for Liquidity Addition

### Overview

The `addLiquidity` function in the `LiquidityPool` contract has been modified to restrict the types of tokens that can be used to add liquidity. Previously, any ERC20 token could be used, but now only specific tokens (GIFT, USDT, and USDC) are permitted. This change ensures the stability and predictability of the liquidity pool by limiting it to known stablecoins and the system's native GIFT token.

### Changes Made

#### Modified Function: `addLiquidity`

The `addLiquidity` function now includes a validation check to ensure that only specific tokens (USDT, USDC, and GIFT) can be added to the liquidity pool. This is enforced through a conditional requirement that checks the token address against the allowed tokens.

```solidity
function addLiquidity(address _token, uint256 _amount) external nonReentrant {
    require(whitelist.isWhitelisted(msg.sender), "Not whitelisted"); // Ensure sender is whitelisted
    require(hasRole(LIQUIDITY_PROVIDER_ROLE, msg.sender), "Not a liquidity provider"); // Ensure sender is a liquidity provider
    //The change in question
    require(_token == usdtToken || _token == usdcToken || _token == giftToken, "Token not allowed"); // Only allow specific tokens
    
    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount); // Transfer tokens safely
    liquidity[_token] += _amount; // Update liquidity mapping

    emit LiquidityAdded(msg.sender, _token, _amount); // Emit an event for liquidity addition
}
```

### Impact & Revertion date

- **Liquidity Providers**: Must use only USDT, USDC, or GIFT tokens to participate in the liquidity pool.
- **Contract Interactions**: Any interactions with the `addLiquidity` function using unsupported tokens will be rejected and will revert the transaction.

This change was Reverted on [4th, May 2024].
