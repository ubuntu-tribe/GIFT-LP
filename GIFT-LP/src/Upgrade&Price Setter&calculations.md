# Deploying Upgradeable Contracts using a Proxy Pattern

To make the Whitelist and PriceManager contracts upgradeable in the LiquidityPool & Tokenswap contracts, follow these steps:

1. Deploy the implementation contracts for Whitelist and PriceManager:
   - Create separate implementation contracts for Whitelist and PriceManager.
   - Ensure that these contracts are properly initialized and have the necessary functionality.

2. Deploy proxy contracts for each implementation contract:
   - Deploy a proxy contract for the Whitelist implementation contract.
   - Deploy a proxy contract for the PriceManager implementation contract.
   - Initialize each proxy contract with the address of its corresponding implementation contract.

3. Pass the proxy addresses when deploying the LiquidityPool & Tokenswap contracts:
   - When deploying the LiquidityPool & Tokenswap contracts, pass the addresses of the Whitelist and PriceManager proxy contracts as constructor arguments.
   - The LiquidityPool & Tokenswap contracts should interact with the Whitelist and PriceManager contracts through their proxy addresses.

By following these steps, you enable the upgradability of the Whitelist and PriceManager contracts within the LiquidityPool & Tokenswap contract. This allows you to update and enhance the features of these contracts without requiring a full redeployment of the LiquidityPool & Tokenswap contract.







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
