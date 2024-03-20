/*// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TokenSwap.sol";

contract DeployTokenSwap is Script {
    function run() external {
        vm.startBroadcast();

        address liquidityPool = address(0); // TODO: Replace with deployed LiquidityPool contract address
        address priceManager = address(0); // TODO: Replace with deployed PriceManager contract address
        address whitelist = address(0); // TODO: Replace with deployed Whitelist contract address

        new TokenSwap(liquidityPool, priceManager, whitelist);

        vm.stopBroadcast();
    }
}*/
