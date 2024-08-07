// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {Sanctions} from "../src/core/Sanctions.sol";

contract Deploy is Script {
    function run() external {
        console.log("Deployer", msg.sender);

        vm.startBroadcast();

        console.log("\n---- START ----");

        address sanctions = address(new Sanctions(vm.envAddress("Owner")));

        console.log("Sanctions: \t\t\t", sanctions);

        console.log("\n---- deployment ended ----\n");

        vm.stopBroadcast();
    }
}
