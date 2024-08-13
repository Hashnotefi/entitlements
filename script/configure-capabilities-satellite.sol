// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {RolesAuthority, Role} from "../src/core/RolesAuthority.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract ConfigureCapabilities is Script {
    function run() external {
        console.log("Sender", msg.sender);

        vm.startBroadcast();

        console.log("\n---- START ----");

        RolesAuthority authority = RolesAuthority(vm.envAddress("RolesAuthority"));

        _authority(authority);
        _usyc(authority);
        _teller(authority);

        console.log("\n---- Capabilities ended ----\n");

        vm.stopBroadcast();
    }

    function _authority(RolesAuthority authority) internal {
        bytes4 pauseSelector = bytes4(keccak256("pause()"));
        bytes4 setUserRoleSelector = bytes4(keccak256("setUserRole(address,uint8,bool)"));
        bytes4 setUserRoleBroadcastSelector = bytes4(keccak256("setUserRoleBroadcast(address,uint8,bool)"));
        bytes4 setUserRoleBatchSelector = bytes4(keccak256("setUserRoleBatch(address[],uint8[],bool[])"));
        bytes4 setUserRoleBatchBroadcastSelector = bytes4(keccak256("setUserRoleBatchBroadcast(address[],uint8[],bool[])"));

        authority.setUserRole(vm.envAddress("MessengerEntitlements"), Role.System_Messenger, true);
        authority.setRoleCapability(Role.System_FundAdmin, address(authority), pauseSelector, true);
        authority.setRoleCapability(Role.System_FundAdmin, address(authority), setUserRoleSelector, true);
        authority.setRoleCapability(Role.System_FundAdmin, address(authority), setUserRoleBroadcastSelector, true);
        authority.setRoleCapability(Role.System_FundAdmin, address(authority), setUserRoleBatchSelector, true);
        authority.setRoleCapability(Role.System_FundAdmin, address(authority), setUserRoleBatchBroadcastSelector, true);


        authority.setRoleCapability(Role.System_Messenger, address(authority), pauseSelector, true);
        authority.setRoleCapability(Role.System_Messenger, address(authority), setUserRoleSelector, true);
        authority.setRoleCapability(Role.System_Messenger, address(authority), setUserRoleBatchSelector, true);

    }

    function _usyc(RolesAuthority authority) internal {
        address usyc = vm.envAddress("USYC");
        authority.setRoleCapability(Role.Investor_SDYFInternational, usyc, IERC20.transfer.selector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, usyc, IERC20.transferFrom.selector, true);
    }

    function _teller(RolesAuthority authority) internal {
        address hnUsdTeller = vm.envAddress("hnUsdTeller");
        address usdcTeller = vm.envAddress("usdcTeller");

        authority.setUserRole(vm.envAddress("FundAdmin"), Role.System_FundAdmin, true);
        authority.setUserRole(hnUsdTeller, Role.System_Teller, true);
        authority.setUserRole(usdcTeller, Role.System_Teller, true);

        bytes4 buySelector = bytes4(keccak256("buy(uint256)"));
        bytes4 buyForSelector = bytes4(keccak256("buyFor(uint256,address)"));
        bytes4 sellSelector = bytes4(keccak256("sell(uint256)"));
        bytes4 sellForSelector = bytes4(keccak256("sellFor(uint256,address)"));
        bytes4 buyWithPermitSelector = bytes4(keccak256("buyWithPermit(address,uint256,address,uint256,uint8,bytes32,bytes32)"));

        authority.setRoleCapability(Role.Investor_SDYFInternational, hnUsdTeller, buySelector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, hnUsdTeller, buyForSelector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, hnUsdTeller, sellSelector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, hnUsdTeller, sellForSelector, true);
        authority.setRoleCapability(Role.System_FundAdmin, hnUsdTeller, buyWithPermitSelector, true);

        authority.setRoleCapability(Role.Investor_SDYFInternational, usdcTeller, buySelector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, usdcTeller, buyForSelector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, usdcTeller, sellSelector, true);
        authority.setRoleCapability(Role.Investor_SDYFInternational, usdcTeller, sellForSelector, true);
        authority.setRoleCapability(Role.System_FundAdmin, usdcTeller, buyWithPermitSelector, true);
    }
}
