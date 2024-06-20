# Detailed Documentation and Architecture for TokenSwap and KYC Contracts

## Table of Contents
1. [Introduction](#introduction)
2. [TokenSwap Contract](#tokenswap-contract)
   - [Contract Overview](#contract-overview)
   - [State Variables](#state-variables)
   - [Events](#events)
   - [Functions](#functions)
     - [initialize](#initialize)
     - [setPremiumWallet](#setpremiumwallet)
     - [setPremiumRate](#setpremiumrate)
     - [updatePremiumRate](#updatepremiumrate)
     - [addTrustedAddress](#addtrustedaddress)
     - [removeTrustedAddress](#removetrustedaddress)
     - [swapTokens](#swaptokens)
     - [swapGiftToOtherTokens](#swapgifttothertokens)
     - [swapTokensforrecipient](#swaptokensforrecipient)
     - [swapGift](#swapgift)
     - [addSwappableToken](#addswappabletoken)
     - [removeSwappableToken](#removeswappabletoken)
     - [setPriceManager](#setpricemanager)
     - [setWhitelist](#setwhitelist)
     - [setLiquidityPool](#setliquiditypool)
     - [setKYC](#setkyc)
     - [transferAdminRole](#transferadminrole)
3. [KYC Contract](#kyc-contract)
   - [Contract Overview](#contract-overview-1)
   - [State Variables](#state-variables-1)
   - [Events](#events-1)
   - [Functions](#functions-1)
     - [initialize](#initialize-1)
     - [grantKYCAccountantRole](#grantkycaccountantrole)
     - [updateKYCAccountantRole](#updatekycaccountantrole)
     - [addKYCLevel](#addkyclevel)
     - [modifyKYCLevel](#modifykyclevel)
     - [removeKYCLevel](#removekyclevel)
     - [assignKYCLevel](#assignkyclevel)
     - [getKYCLevel](#getkyclevel)
     - [getKYCLevels](#getkyclevels)
     - [AdmingetKYCLevels](#admingetkyclevels)
4. [Contract Interaction and Flow](#contract-interaction-and-flow)
5. [Deployment Instructions](#deployment-instructions)
6. [Context and Design Choices](#Context-and-Design-Choices)
7. [Setup](#Setup-Instructions)


## Introduction
The TokenSwap and KYC contracts are designed to facilitate secure and compliant token swapping while incorporating KYC (Know Your Customer) functionality. The TokenSwap contract allows users to swap between different tokens, with configurable premium rates and trusted addresses. The KYC contract manages user verification levels and swap limits, ensuring that users meet the necessary requirements to participate in token swaps.

This documentation provides a detailed overview of the contract architecture, including state variables, events, and functions. It also covers the interaction flow between the contracts and provides deployment instructions and security considerations.

## TokenSwap Contract

### Contract Overview
The TokenSwap contract is an upgradable contract that inherits from OpenZeppelin's `AccessControlUpgradeable` and `ReentrancyGuardUpgradeable` contracts. It allows users to swap tokens, with support for premium rates, trusted addresses, and integration with external contracts such as LiquidityPool, PriceManager, Whitelist, and KYC.

### State Variables
- `swappableTokens`: Mapping to track which tokens are swappable.
- `premiumRates`: Mapping to store premium rates for specific addresses.
- `trustedAddresses`: Mapping to store trusted addresses that can bypass KYC and whitelist checks.
- `liquidityPool`: LiquidityPool contract instance.
- `priceManager`: PriceManager contract instance.
- `whitelist`: Whitelist contract instance.
- `kycPermissions`: KYC contract instance.
- `premiumWallet`: Address to receive premium fees.

### Events
- `TokensSwapped`: Emitted when tokens are swapped, providing details about the swap.
- `PremiumRateUpdated`: Emitted when the premium rate for an address is updated.

### Functions

#### initialize
```solidity
function initialize(address _liquidityPool, address _priceManager, address _whitelist, address _kycPermissions) public initializer
```
Initializes the TokenSwap contract with the addresses of the LiquidityPool, PriceManager, Whitelist, and KYC contracts. Grants the DEFAULT_ADMIN_ROLE to the contract deployer.

#### setPremiumWallet
```solidity
function setPremiumWallet(address _newPremiumWallet) external
```
Sets the address of the premium wallet. Only the admin can call this function.

#### setPremiumRate
```solidity
function setPremiumRate(address _address, uint256 _rate) external
```
Sets the premium rate for a specific address. Only the admin can call this function. The rate must be less than or equal to 5%.

#### updatePremiumRate
```solidity
function updatePremiumRate(address _address, uint256 _newRate) external
```
Updates the premium rate for a specific address. Only the admin can call this function. The new rate must be less than or equal to 5%.

#### addTrustedAddress
```solidity
function addTrustedAddress(address _address) external
```
Adds an address to the list of trusted addresses. Only the admin can call this function.

#### removeTrustedAddress
```solidity
function removeTrustedAddress(address _address) external
```
Removes an address from the list of trusted addresses. Only the admin can call this function.

#### swapTokens
```solidity
function swapTokens(address _token, uint256 _amountIn, address _recipient) external nonReentrant
```
Allows users to swap other tokens for GIFT tokens. The recipient must be the sender. Performs necessary checks, calculates swap amounts and fees, and updates token balances.

#### swapGiftToOtherTokens
```solidity
function swapGiftToOtherTokens(address _token, uint256 _amountIn, address _recipient) external nonReentrant
```
Allows users to swap GIFT tokens for other tokens. Performs necessary checks, calculates swap amounts and fees, and updates token balances.

#### swapTokensforrecipient
```solidity
function swapTokensforrecipient(address _token, uint256 _amountIn, address _recipient) external nonReentrant
```
Allows whitelisted addresses to swap other tokens for GIFT and send them to a specified recipient. Performs necessary checks, calculates swap amounts and fees, and updates token balances.

#### swapGift
```solidity
function swapGift(address _token, uint256 _amountIn, address _recipient) external nonReentrant
```
Allows users to swap GIFT tokens for other tokens. The recipient must be the sender. Performs necessary checks, calculates swap amounts and fees, and updates token balances.

#### addSwappableToken
```solidity
function addSwappableToken(address _token) external
```
Adds a token to the list of swappable tokens. Only the admin can call this function.

#### removeSwappableToken
```solidity
function removeSwappableToken(address _token) external
```
Removes a token from the list of swappable tokens. Only the admin can call this function.

#### setPriceManager
```solidity
function setPriceManager(address _priceManager) external
```
Updates the address of the PriceManager contract. Only the admin can call this function.

#### setWhitelist
```solidity
function setWhitelist(address _whitelist) external
```
Updates the address of the Whitelist contract. Only the admin can call this function.

#### setLiquidityPool
```solidity
function setLiquidityPool(address _LiquidityPool) external
```
Updates the address of the LiquidityPool contract. Only the admin can call this function.

#### setKYC
```solidity
function setKYC(address _KycPermissions) external
```
Updates the address of the KYC contract. Only the admin can call this function.

#### transferAdminRole
```solidity
function transferAdminRole(address newAdmin) external
```
Transfers the admin role to a new address. Only the current admin can call this function.

## KYC Contract

### Contract Overview
The KYC contract is an upgradable contract that inherits from OpenZeppelin's `AccessControlUpgradeable` contract. It manages KYC (Know Your Customer) levels and assigns them to user addresses. The contract allows the admin to add, modify, and remove KYC levels, and grants the KYC_ACCOUNTANT_ROLE to specific addresses to assign KYC levels to users.

### State Variables
- `KYC_ACCOUNTANT_ROLE`: Role identifier for KYC accountants.
- `kycLevels`: Array to store KYC levels.
- `addressToKYCLevel`: Mapping to store the assigned KYC level ID for each user address.

### Events
- `KYCLevelAdded`: Emitted when a new KYC level is added.
- `KYCLevelModified`: Emitted when a KYC level is modified.
- `KYCLevelRemoved`: Emitted when a KYC level is removed.
- `KYCLevelAssigned`: Emitted when a KYC level is assigned to a user address.

### Functions

#### initialize
```solidity
function initialize() public initializer
```
Initializes the KYC contract and grants the DEFAULT_ADMIN_ROLE to the contract deployer.

#### grantKYCAccountantRole
```solidity
function grantKYCAccountantRole(address _account) external onlyRole(DEFAULT_ADMIN_ROLE)
```
Grants the KYC_ACCOUNTANT_ROLE to an address. Only the admin can call this function.

#### updateKYCAccountantRole
```solidity
function updateKYCAccountantRole(address _currentAccountant, address _newAccountant) external onlyRole(DEFAULT_ADMIN_ROLE)
```
Updates the address holding the KYC_ACCOUNTANT_ROLE. Only the admin can call this function.

#### addKYCLevel
```solidity
function addKYCLevel(string memory _name, uint256 _swapLimit) external onlyRole(DEFAULT_ADMIN_ROLE)
```
Adds a new KYC level with the given name and swap limit. Only the admin can call this function.

#### modifyKYCLevel
```solidity
function modifyKYCLevel(uint256 _levelId, string memory _name, uint256 _swapLimit) external onlyRole(DEFAULT_ADMIN_ROLE)
```
Modifies an existing KYC level with the given level ID, name, and swap limit. Only the admin can call this function.

#### removeKYCLevel
```solidity
function removeKYCLevel(uint256 _levelId) external onlyRole(DEFAULT_ADMIN_ROLE)
```
Removes an existing KYC level with the given level ID. Only the admin can call this function.

#### assignKYCLevel
```solidity
function assignKYCLevel(address _account, uint256 _levelId) external onlyRole(KYC_ACCOUNTANT_ROLE)
```
Assigns a KYC level to a user address. Only addresses with the KYC_ACCOUNTANT_ROLE can call this function.

#### getKYCLevel
```solidity
function getKYCLevel(address _account) external view returns (uint256)
```
Retrieves the assigned KYC level ID for a user address.

#### getKYCLevels
```solidity
function getKYCLevels() external view returns (KYCLevel[] memory)
```
Retrieves all KYC levels.

#### AdmingetKYCLevels
```solidity
function AdmingetKYCLevels() external view returns (KYCLevel[] memory)
```
Allows the admin to retrieve all KYC levels.

## Contract Interaction and Flow

1. The admin deploys the LiquidityPool, PriceManager, Whitelist, and KYC contracts.
2. The admin deploys the TokenSwap contract, passing the addresses of the previously deployed contracts to the `initialize` function.
3. The admin adds swappable tokens using the `addSwappableToken` function in the TokenSwap contract.
4. The admin sets premium rates for specific addresses using the `setPremiumRate` function in the TokenSwap contract.
5. The admin adds trusted addresses that can bypass KYC and whitelist checks using the `addTrustedAddress` function in the TokenSwap contract.
6. The admin adds KYC levels using the `addKYCLevel` function in the KYC contract.
7. The admin grants the KYC_ACCOUNTANT_ROLE to specific addresses using the `grantKYCAccountantRole` function in the KYC contract.
8. KYC accountants assign KYC levels to user addresses using the `assignKYCLevel` function in the KYC contract.
9. Users can perform token swaps using the various swap functions in the TokenSwap contract, such as `swapTokens`, `swapGiftToOtherTokens`, `swapTokensforrecipient`, and `swapGift`.
10. The TokenSwap contract interacts with the LiquidityPool, PriceManager, Whitelist, and KYC contracts to perform necessary checks and update token balances.

## Deployment Instructions

1. Deploy the LiquidityPool contract with the necessary constructor arguments.
2. Deploy the PriceManager contract.
3. Deploy the Whitelist contract.
4. Deploy the KYC contract.
5. Deploy the TokenSwap contract, passing the addresses of the LiquidityPool, PriceManager, Whitelist, and KYC contracts to the `initialize` function.
6. Use the admin functions in the TokenSwap and KYC contracts to set up swappable tokens, premium rates, trusted addresses, and KYC levels.

Note: Only the TokenSwap and KYC contracts need to be redeployed if updates are made. The entire system remains the same, and the TokenSwap contract should be deployed with the addresses of all the other existing contracts.

## Context and Design Choices

The TokenSwap contract has been designed to provide a flexible and secure token swapping system that caters to various use cases and user roles. The following sections explain the key design choices and functionalities implemented in the contract.

### Swappable Tokens
- The `AddSwapableToken` function remains unchanged, allowing the admin to add tokens that can be swapped within the system.

### Trusted Addresses
- The `AddTrustedAddress` function is introduced to support backend services and off-ramp services.
- Trusted addresses are exempt from whitelist and KYC checks, enabling seamless integration with backend systems.
- Off-ramp services, when registered as trusted addresses, can perform swaps without incurring any fees.

### Premium Rates
- The contract now includes the ability to set and modify premium rates for specific addresses.
- When an off-ramp service registers and wants to swap tokens, the admin can add their address and set the premium rate to zero.
- This functionality allows off-ramp services to perform swaps without being charged any premium fees.

### KYC Contract Address
- The `setKYC` function allows the admin to update the address of the KYC contract.
- This flexibility is important in case the KYC contract needs to be updated or replaced for security reasons or other considerations.
- While the KYC contract is being updated or is unavailable, token swaps will not be processed to ensure compliance with KYC requirements.

### Liquidity Pool Contract Address
- Similar to the KYC contract, the `setLiquidityPool` function enables the admin to update the address of the LiquidityPool contract.
- This allows for flexibility in managing the liquidity pool and ensures that the TokenSwap contract interacts with the correct liquidity pool instance.

### Price Manager Contract Address
- The `setPriceManager` function allows the admin to set the address of the PriceManager contract.
- This contract is responsible for managing token prices and is a critical component of the token swapping system.

### Whitelist Contract Address
- The `setWhitelist` function enables the admin to update the address of the Whitelist contract.
- The Whitelist contract maintains a list of approved addresses that are allowed to participate in token swaps.

### Token Swapping Functions
- The `swapGift` and `swapTokens` functions are designed for end-users who want to swap tokens for themselves.
- To ensure that end-users are the ones performing the swaps, the recipient address must match the address initiating the swap.
- This prevents unauthorized third parties from swapping tokens on behalf of end-users without their consent.

### Token Swapping for Recipients
- The `swapGiftToOtherTokens` and `swapTokensforrecipient` functions are intended for services that are allowed to swap tokens on behalf of other recipients.
- These functions are particularly useful for off-ramp services that need to swap tokens and send them to user-specified recipient addresses.
- The contract includes necessary checks and restrictions to ensure that only authorized services can perform swaps for other recipients.

By incorporating these design choices and functionalities, the TokenSwap contract provides a robust and adaptable token swapping system. It accommodates the needs of end-users, backend services, and off-ramp services while maintaining security and compliance with KYC requirements. The contract's modular architecture allows for easy integration with other components such as the KYC contract, LiquidityPool contract, PriceManager contract, and Whitelist contract, enabling a seamless token swapping experience for all participants in the ecosystem.


## Setup Instructions

This section provides a step-by-step guide on how to deploy and set up the KYC and TokenSwap contracts. Please refer to the previous sections of this document for detailed explanations of the various functions and their meanings.

### KYC Contract Deployment
1. Deploy the KYC contract.
2. Set the KYC accountant role to an address using the `grantKYCAccountantRole` function.
3. Add a KYC level using the `addKYCLevel` function, specifying the level name and swap limit.
4. Assign the KYC level to user addresses using the `assignKYCLevel` function.

### TokenSwap Contract Deployment
1. Deploy the TokenSwap contract, providing the current addresses of the existing smart contracts (LiquidityPool, PriceManager, Whitelist, and KYC).

### Post-Deployment Setup
After deploying the TokenSwap contract, follow these steps to complete the setup:

1. Grant allowance on all tokens:
   - On your account, grant maximum allowance to the TokenSwap contract for all the tokens you intend to swap.

2. Add the TokenSwap contract to the Whitelist:
   - Go to the Whitelist contract and add the TokenSwap contract address using the `addWhitelisted` function.
   - Add the TokenSwap contract address as a whitelister using the `addWhitelister` function.

3. Grant the liquidity provider role to the TokenSwap contract:
   - Go to the LiquidityPool contract and grant the liquidity provider role to the TokenSwap contract using the appropriate function.

4. Add swappable tokens:
   - In the TokenSwap contract, add the three swappable tokens using the `addSwappableToken` function.

5. Set the premium wallet:
   - Set the address of the premium wallet using the `setPremiumWallet` function in the TokenSwap contract.

### Token Swapping
After completing the setup, you can proceed to swap tokens based on the KYC levels you have set:

- If you have assigned a KYC level to your address, you can swap tokens within the limits defined by that KYC level.
- If you want to test the trusted address functionality:
  1. Add your wallet address as a trusted address using the `addTrustedAddress` function in the TokenSwap contract.
  2. With your wallet set as a trusted address, you can swap tokens without any KYC or whitelist limits.
