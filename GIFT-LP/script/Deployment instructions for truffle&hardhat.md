# Ethereum Smart Contract Deployment Guide

According to Oliver, foundry isn't a primary framework in this project so this guide provides instructions on how to initialize the project, run the smart contracts, and deploy using Truffle and Hardhat.

## Using Truffle

### 1. Installing Truffle

To get started with Truffle, you first need to install it globally on your machine using npm:

```bash
npm install -g truffle
```

### 2. Initializing a Truffle Project

Navigate to your project directory and run:

```bash
truffle init
```

This command sets up the necessary files and directories for your project.

### 3. Writing Smart Contracts

Place your Solidity smart contracts in the `contracts/` directory. For example, `MyContract.sol`.

### 4. Compiling Contracts

Compile your contracts to generate the ABI and bytecode:

```bash
truffle compile
```

### 5. Migration Scripts

Create a migration script in the `migrations/` directory to specify how to deploy your contracts. For example, `2_deploy_contracts.js`:

```javascript
const MyContract = artifacts.require("MyContract");

module.exports = function (deployer) {
  deployer.deploy(MyContract);
};
```

### 6. Configuring Networks

Configure your desired networks in `truffle-config.js`, specifying host, port, network_id, and other necessary details for deployment.

```javascript
module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id
    },
  },
  // Additional configuration settings
};
```

### 7. Deploying Contracts

Deploy your contracts using Truffle's migration system:

```bash
truffle migrate --network development
```

Replace `development` with the network you wish to deploy to.

## Using Hardhat

### 1. Installing Hardhat

Initialize a new npm package and install Hardhat:

```bash
npm init -y
npm install --save-dev hardhat
```

### 2. Creating a Hardhat Project

Create a Hardhat project by running:

```bash
npx hardhat
```

Follow the prompts to set up your project. Choose "Create a sample project" to get a basic project structure.

### 3. Writing Smart Contracts

Place your Solidity smart contracts in the `contracts/` directory.

### 4. Compiling Contracts

Compile your contracts by running:

```bash
npx hardhat compile
```

### 5. Writing Deployment Scripts

Create a script under the `scripts/` directory to deploy your contracts. For example, `deploy.js`:

```javascript
async function main() {
  const MyContract = await ethers.getContractFactory("MyContract");
  const myContract = await MyContract.deploy();

  console.log("Contract deployed to:", myContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

### 6. Configuring Networks

Configure your deployment networks in `hardhat.config.js`. For example, to add the Ropsten test network:

```javascript
module.exports = {
  solidity: "0.8.4",
  networks: {
    ropsten: {
      url: "https://ropsten.infura.io/v3/YOUR_INFURA_PROJECT_ID",
      accounts: [`0x${YOUR_PRIVATE_KEY}`],
    },
  },
};
```

### 7. Deploying Contracts

Deploy your contracts to the desired network:

```bash
npx hardhat run scripts/deploy.js --network ropsten
```
