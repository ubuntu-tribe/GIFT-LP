# Updating whitelist & pricemanager

functions have been added to the lp and tokenswap contract to update the whitelist and price manager contract




# Liquidity Pool and Token Swap Updates

## Main Changes

1. Updated the `swapTokens` and `swapTokensforrecipient` function in the `TokenSwap` contract:
   - The `_amountIn` represents the amount of USDC (or other tokens) being swapped, which has 6 decimal places.
   - The `giftPrice` is the price of GIFT tokens in cents (0.072 in your example), which has 18 decimal places.
   - To calculate the amount of GIFT tokens to be received (`amountOut`), multiply `_amountIn` by `1e18` (to match the decimal places of `giftPrice`) and then divide by `giftPrice`.

2. Ensure that the `giftPrice` variable in the `PriceManager` contract is updated correctly to reflect the price of GIFT tokens in cents with 18 decimal places. For example, if the price is 0.072 cents per milligram, the `giftPrice` should be set to `72000000000000000` (0.072 * 1e18).







# Changes Made to the PriceManager Contracts

## PriceManager Contract

1. Added the OpenZeppelin `AccessControl` contract:
   ```solidity
   import "@openzeppelin/contracts/access/AccessControl.sol";
   ```

2. Changed the contract declaration to inherit from both `Ownable` and `AccessControl`:
   ```solidity
   contract PriceManager is Ownable, AccessControl {
       // ...
   }
   ```

3. Defined the `PRICE_SETTER_ROLE`:
   ```solidity
   bytes32 public constant PRICE_SETTER_ROLE = keccak256("PRICE_SETTER_ROLE");
   ```

4. Granted the `PRICE_SETTER_ROLE` to the contract owner in the constructor:
   ```solidity
   constructor(address _shibPriceFeed) Ownable(msg.sender) {
       shibPriceFeed = AggregatorV3Interface(_shibPriceFeed);
       _grantRole(PRICE_SETTER_ROLE, msg.sender);
   }
   ```

5. Modified the `setGiftPrice` function to allow both the contract owner and the `PRICE_SETTER_ROLE` to set the gift price:
   ```solidity
   function setGiftPrice(uint256 _price) external {
       require(hasRole(PRICE_SETTER_ROLE, msg.sender) || owner() == msg.sender, "Not authorized to set gift price");
       giftPrice = _price;
   }
   ```

6. Added functions to grant and revoke the `PRICE_SETTER_ROLE`:
   ```solidity
   function grantPriceSetterRole(address _account) external onlyOwner {
       _grantRole(PRICE_SETTER_ROLE, _account);
   }

   function revokePriceSetterRole(address _account) external onlyOwner {
       _revokeRole(PRICE_SETTER_ROLE, _account);
   }
   ```
