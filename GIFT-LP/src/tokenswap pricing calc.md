# Token pricing  calculation Swap Documentation

## Swap Tokens and Swap Tokens for Recipient Functions

In the `swapTokens` and `swapTokensForRecipient` functions, the following calculation is performed:

```solidity
uint256 amountOut = (_amountIn * 1e12) / giftPrice;
```

Here's how it works:

- `_amountIn` is the amount of USDC tokens being swapped, with 6 decimal places.
- We multiply `_amountIn` by 10^12 (1e12) to convert USDC to an equivalent value with 18 decimal places.
- `giftPrice` is the price of GIFT in US dollars, represented with 18 decimal places.
- By dividing `(_amountIn * 1e12)` by `giftPrice`, we calculate the amount of GIFT tokens equivalent to the given `_amountIn` of USDC tokens.

Let's go through an example:

- Assume `_amountIn` is 10, representing 10 USDC tokens.
- `giftPrice` is set to 72000000000000000, representing 0.072 US dollars with 18 decimal places.
- The `amountOut` calculation will be:
  ```
  amountOut = (10 * 1e12) / 72000000000000000
            = 10000000000000 / 72000000000000000
            = 0.138888888888888888 (in 18 decimal places)
            = 138888888888888888 (as a uint256 value)
  ```
- The resulting `amountOut` is 138888888888888888, which represents 138.888888888888888888 GIFT tokens with 18 decimal places.

So, with this modification, when a user swaps 10 USDC tokens, they will receive approximately 138.888889 GIFT tokens (rounded to 6 decimal places).
