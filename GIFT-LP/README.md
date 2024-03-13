# Architectural Documentation of Smart Contracts

## Smart Contract Structure

The project will comprise four core smart contracts:
- LiquidityPool.sol
- PriceManager.sol
- TokenSwap.sol
- Whitelist.sol

## Contract Descriptions and Enhancements

### 1. LiquidityPool.sol

#### State Variables:
- `giftToken`: Address of the GIFT token.
- `usdcToken`: Address of the USDC token.
- `usdtToken`: Address of the USDT token.
- `otherSwappableTokens`: Array for supported tokens (for now shib).
- `liquidity`: Mapping (address => uint256) for user liquidity tracking.
- `giftPrice`: Price of GIFT.
- `premiums`: Array of premium structures (e.g., struct Premium{ uint256 percentage; address permissionAddress}).

#### Roles (OpenZeppelin Access Control):
- `DEFAULT_ADMIN_ROLE`: Contract owner.
- `LIQUIDITY_PROVIDER_ROLE`: (Whitelisted) Addresses allowed to add/remove liquidity.
- `PRICE_SETTER_ROLE`: Address allowed to set the GIFT price.
- `PREMIUM_MANAGER_ROLE`: (An array of addresses given the permission by the admin) to set the premium % of a transaction to anything other than the default 5% (When they call a swap transaction they can are also able to edit the premium anywhere from 0% to 5%).

#### Main Features:
- Integration with `Whitelist.sol` to check for whitelisted addresses before allowing liquidity operations.
- Utilization of OpenZeppelin's `Ownable` for administrative actions and `AccessControl` for defining roles like `LIQUIDITY_PROVIDER_ROLE`.
- Dynamic liquidity tracking with events for liquidity addition and removal.
- Functionality to interact with `PriceManager.sol` for real-time value calculations of liquidity based on current GIFT and other tokens' prices.
- Advanced features such as setting and monitoring liquidity thresholds for alerts.
- Implements a function to withdraw stablecoins from liquidity for buying gold.

#### Events:
- LiquidityAdded
- LiquidityRemoved
- GiftPriceChanged
- StablecoinsWithdrawn
- LiquidityThresholdAlert 

### 2. PriceManager.sol

#### Dependencies and role:
- Chainlink Aggregator Interfaces (AggregatorV3Interface)
- Manages price feeds for GIFT and other tokens, supports manual price adjustments, and integrates with external price sources like Chainlink.

#### State Variables:
- `tokenPriceFeeds`: Mapping (tokenAddress => AggregatorV3Interface)

#### Features:
- Chainlink Oracles integration for live market prices and the ability to manually override prices by admins.
- `getLatestTokenPrice(address _token)`: Fetches the latest price from Chainlink.
- `updatePriceFeed(address _token, address _feedAddress)`: External, with DEFAULT_ADMIN_ROLE.
- `GiftPrice()`: The Gift price which can be set by an Admin.
- Access control for price setting operations, secured with OpenZeppelin's `Ownable`.

#### SHIB Integration
"SHIB > USDC > GIFT" swap directly within the smart contract, using Chainlink for price feeds to determine the exchange rates, is extremely feasible. It allows for a streamlined user experience and can potentially reduce slippage by locking in prices at the moment of the transaction.

##### User Interface Level Workflow
1. User Selection: The user selects the amount of SHIB they wish to swap for GIFT tokens through the platform's UI.
2. Price Calculation: The UI queries the `PriceManager.sol` contract to get the latest SHIB to USDC price, and then calculates the amount of GIFT tokens the user will receive, factoring in any premiums or fees.
3. Transaction Initiation: The user approves the SHIB tokens for transfer and initiates the swap transaction.
4. Confirmation: The UI displays a confirmation with the transaction details, including the SHIB spent, USDC equivalent, and GIFT received.

##### Smart Contract Level
- We import the Chainlink AggregatorV3Interface to interact with the price feed contract.
- We define the priceFeed variable and set it to the address of the SHIB/USD price feed contract in the constructor. 
- We define a function `getLatestShibUsdcPrice()` that retrieves the latest price data from the Chainlink oracle using the `latestRoundData()` function. The price is returned as an int256 value.
- In the `swapShibToGift()` function, we call `getLatestShibUsdcPrice()` to get the current SHIB/USDC price and use it to calculate the equivalent USDC amount based on the provided SHIB amount.

### 3. TokenSwap.sol

#### Dependencies: 
- LiquidityPool.sol
- PriceManager.sol
- Whitelist.sol

#### Features:
- `swapTokens(address _token, uint256 _amountIn)`: External, verifies whitelisting, calculates premiums, fetches prices, and executes the swap via LiquidityPool.
- `swapGiftToOtherTokens(address _token, uint256 _amountOut)`: External, similar logic to swapTokens for GIFT to other token swaps.
- Defines a mapping to store the list of swappable tokens and their corresponding addresses.
- Implements functions to add and remove swappable tokens by an admin role.
- Integrates with the `Whitelist` contract to ensure only whitelisted addresses can perform token swaps.
- Integrates with the `PriceManager` contract to fetch the current price of GIFT token.

#### Events:
- TokensSwapped

### 4. Whitelist.sol

#### State Variables:
- `whitelistedAddresses`: Mapping (address => bool)

#### Roles:
- DEFAULT_ADMIN_ROLE

#### Features:
- `addToWhitelist(address _address)`: External, with DEFAULT_ADMIN_ROLE.
- `removeFromWhitelist(address _address)`: External, with DEFAULT_ADMIN_ROLE.
- `isWhitelisted(address _address)`: External view function.
- Utilization of OpenZeppelin's `Ownable` for managing whitelist modifications securely.

## Cross-Contract Interactions and External Integrations

- Contracts interact seamlessly, with `LiquidityPool.sol` and `TokenSwap.sol` referencing `Whitelist.sol` for authorization checks and `PriceManager.sol` for pricing information.
- External data feeds from Chainlink are integrated via `PriceManager.sol`, ensuring accurate and up-to-date pricing for swap operations and liquidity management.
- The system is designed with scalability in mind, accommodating future tokens and pricing sources through `PriceManager.sol`.

## Security
- The use of SafeMath for all arithmetic operations to prevent overflows and underflows.
- Reentrancy guards:
  - LiquidityPool.sol: The addLiquidity and removeLiquidity functions should have reentrancy guards to prevent multiple invocations from the same transaction.
  - TokenSwap.sol: The token swapping functionality involves transferring tokens between the contract and users. Reentrancy guards will be implemented to prevent malicious actors from exploiting the swapping process.
- We ensure that the contract's state is updated (e.g., updating token balances) before making any external calls or transfers.
- Gas efficiency is a core consideration, with optimizations such as minimizing state changes and using efficient data structures.
- Adopts a proxy pattern for upgradeability, allowing for future improvements and fixes without compromising on decentralization or security.
- Access control is finely grained with OpenZeppelin's `AccessControl`, giving precise permissions for different operations.