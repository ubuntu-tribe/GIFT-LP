/*// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/PriceManager.sol";

contract DeployPriceManager is Script {
    function run() external {
        vm.startBroadcast();

        // Example SHIB price feed address, replace with actual Chainlink Data Feed address
        address shibPriceFeed = address(0); // TODO: Replace with actual SHIB price feed address

        new PriceManager(shibPriceFeed);

        vm.stopBroadcast();
    }
}*/
