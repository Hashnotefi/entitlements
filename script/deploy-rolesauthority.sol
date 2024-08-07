// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {RolesAuthority} from "../src/core/RolesAuthority.sol";
import {RolesAuthorityProxy} from "../src/core/RolesAuthorityProxy.sol";

contract DeployRolesAuthority is Script {
    function run() external {
        console.log("Deployer", msg.sender);

        vm.startBroadcast();

        console.log("\n---- START ----");

        address implementation = address(new RolesAuthority(vm.envAddress("Sanctions"), vm.envAddress("Messenger")));

        console.log("RolesAuthority: \t\t", implementation);

        console.log("\n---- deployment ended ----\n");

        vm.stopBroadcast();
    }
}
