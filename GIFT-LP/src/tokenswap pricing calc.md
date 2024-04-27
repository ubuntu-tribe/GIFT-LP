# Token pricing  calculation Swap Documentation

## Swap Tokens and Swap Tokens for Recipient Functions

In the `swapTokens` and `swapTokensForRecipient` functions, the following calculation is performed:

```solidity
uint256 amountOut = (_amountIn * 1e30) / giftPrice;
```

