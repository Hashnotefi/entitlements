// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {RolesAuthority, Role} from "../src/core/RolesAuthority.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract ConfigureUsycCapabilities is Script {
    function run() external {
        console.log("Sender", msg.sender);

        vm.startBroadcast();

        console.log("\n---- START ----");

        RolesAuthority authority = RolesAuthority(vm.envAddress("RolesAuthority"));
        address usyc = vm.envAddress("USYC");

        authority.setRoleCapability(Role.Investor_SDYFInternational, usyc, IERC20.transfer.selector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, usyc, IERC20.transferFrom.selector, true);

        console.log("\n---- Capabilities ended ----\n");

        vm.stopBroadcast();
    }
}
