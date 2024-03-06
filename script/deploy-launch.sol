// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {RolesAuthority} from "../src/core/RolesAuthority.sol";
import {RolesAuthorityProxy} from "../src/core/RolesAuthorityProxy.sol";

contract Deploy is Script {
    function run() external {
        console.log("Deployer", msg.sender);

        vm.startBroadcast();

        console.log("\n---- START ----");

        address implementation = address(new RolesAuthority(address(vm.envAddress("Sanctions"))));
        bytes memory initData = abi.encodeWithSelector(RolesAuthority.initialize.selector, address(this));
        address proxy = address(new RolesAuthorityProxy(implementation, initData));

        console.log("RolesAuthority: \t\t", implementation);
        console.log("RolesAuthorityProxy: \t\t", proxy);

        console.log("\n---- deployment ended ----\n");

        vm.stopBroadcast();
    }
}
