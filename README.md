# GIFT-LP
Liquidity swapping Pool GIFT
##FUNCTIONAL REQUIREMENTS:
##Add Liquidity Functionality:
Users should be able to add liquidity to the pool by depositing a specified amount of tokens. The liquidity added by users should increase the overall liquidity pool size.
We need an allowance Role to set the users allowed to add and remove Liquidity (Oppenzeppelin Roles)
Remove Liquidity Functionality:
Users should have the ability to remove liquidity from the pool, withdrawing their share of tokens from the pool. Upon withdrawal, the liquidity pool size should decrease accordingly.
##Token Swapping:
Users should be able to swap tokens against the main token GIFT within the liquidity pool.
Token to Swap
•	USDC <> GIFT
•	USDT <> GIFT
•	SHIB <> GIFT
The swapping functionality should execute trades at defines price rates with no slippage.
The Premium to Swap Tokens is 5% on GIFT Pmarket Price (Known as UTribe GIFT at Premium)
##Set Price
The Price of Gift can be set and the swaps are calculated with that price (Gold Price per mg = 1 GIFT Token). Add a role and give permissions to set price.
Add New Swappable Tokens:
There should be a mechanism to add new tokens to the liquidity pool for swapping against GIFT. The addition of new tokens should follow a standardized process and ensure compatibility with existing functionalities. This should be stored in a array and it should be possible to remove tokens as well.
Whitelist Functionality:
The contract should incorporate a whitelist of addresses that are allowed to swap tokens. Only whitelisted addresses should be able to execute swaps within the liquidity pool. This are primary our Partners for ON-/Off-Ramp. Later we will add a DID check function (Decentralized identifier) to allow our verified (KYC) Wallet users to swap directly.
OpenZeppelin Integration:
Basic functionalities such as access control, ownership, and upgradeability should be implemented using OpenZeppelin libraries. The contract should be upgradeable to accommodate future enhancements and fixes.
##Events:
All acrions like add/remove tokens, Liquidity or swaps should trigger events.
 
#NON-FUNCTIONAL REQUIREMENTS:
##Security:
The contract should be thoroughly audited for potential security vulnerabilities. Best practices for secure smart contract development should be followed to mitigate risks.
##Efficiency:
Smart contract functions should be optimized for gas efficiency to minimize transaction costs for users.
##Scalability:
The liquidity pool should be designed to handle a large number of users and transactions without significant performance degradation.
##Interoperability:
The contract should adhere to Ethereum standards to ensure compatibility with existing decentralized finance (DeFi) ecosystems.
Mainly we launch the contract on Polygon, ETH and Binance.
##Deliverables:
Smart Contract Code:
Solidity code implementing the functionalities outlined in the requirements document. Code should be well-commented and follow best practices for readability and maintainability.
##Test Cases:
Comprehensive test suite covering all aspects of the smart contract functionality. Tests should include both positive and negative scenarios to ensure robustness. On Testnets and Mainnet.
##Documentation:
Detailed documentation explaining the contract architecture, functionalities, and usage instructions.
Instructions for deploying the contract and interacting with it on the Ethereum blockchain.
##Supporting Toolset:
A script library to interact with the contract, developed in node.js and accessible and protected by our API Layer and automated backend services
##Audit Report:
A security audit report conducted by a reputable third-party auditing firm, highlighting any vulnerabilities found and recommendations for remediation.
##Deployment Assistance:
Support for deploying the smart contract on the Polygon and Ethereum mainnet or testnets. Guidance on setting up and configuring the contract for optimal performance.
 
#Project Details
##Timeline:
The estimated timeline for the completion of this project is 4-8 weeks, broken down as follows:
•	Requirement Gathering and Design: 1 weeks
•	Smart Contract Development: 2 weeks
•	Testing and Quality Assurance: 1 weeks
•	Documentation and Audit: 2 weeks
•	Deployment and Finalization: 1 weeks
##Project Team:
•	Project Manager Oliver Lienhard
•	Blockchain Developer TBD
•	Smart Contract Auditor AllSEcure
•	Quality Assurance Engineer TBD
•	Documentation Specialist TBD

#USER STORIES
##Liquidity
We as Ubuntu Tribe want to add Liquidity, remove Liquidity and monitor Liquidity on our dashboard, We also like aletrs on certain triggers.
We as Utribe like to withdraw stablecoins from Liquidity to buy more gold.
##Swapping
A whitelisted user (primary) our partners should be able to swap tokens 
Wallet Users DID
TBD Research with Swissfortress how DID’s are stored on chain and how we can verify.

