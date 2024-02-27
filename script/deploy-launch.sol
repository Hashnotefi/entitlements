// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

contract Deploy is Script {
    function run() external {
        console.log("Deployer", msg.sender);

        vm.startBroadcast();

        console.log("\n---- START ----");

        // console.log(": \t\t\t", implementation);
        // console.log(" Proxy: \t\t", proxy);

        console.log("\n---- deployment ended ----\n");

        vm.stopBroadcast();
    }
}
