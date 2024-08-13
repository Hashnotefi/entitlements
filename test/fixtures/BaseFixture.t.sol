// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {Sanctions} from "../../src/core/Sanctions.sol";
import {RolesAuthority} from "../../src/core/RolesAuthority.sol";
import {RolesAuthorityProxy} from "../../src/core/RolesAuthorityProxy.sol";
import {Role} from "../../src/config/enums.sol";

import {MockMessenger} from "../mocks/MockMessenger.sol";

/**
 * helper contract with shared logic for fixtures to inherit
 */
abstract contract BaseFixture is Test {
    RolesAuthority public rolesAuthority;
    Sanctions internal sanctions;
    MockMessenger internal messenger;

    Role internal role;

    address public alice;
    address public charlie;
    address public bob;

    // constants for testing
    address internal constant USER = address(0xBEEF);
    address internal constant TARGET = address(0xCAFE);

    bytes4 internal constant FUNCTION_SIG = bytes4(0xBEEFCAFE);

    event Broadcast(bytes payload);
    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    constructor() {
        charlie = address(0xcccc);
        vm.label(charlie, "Charlie");

        bob = address(0xb00b);
        vm.label(bob, "Bob");

        alice = address(0xaaaa);
        vm.label(alice, "Alice");

        vm.label(USER, "User");
        vm.label(TARGET, "Target");

        sanctions = new Sanctions(address(this));
        messenger = new MockMessenger();

        address implementation = address(new RolesAuthority(address(sanctions), address(messenger)));
        bytes memory initData = abi.encodeWithSelector(RolesAuthority.initialize.selector, charlie);
        address rolesAuthorityProxy = address(new RolesAuthorityProxy(implementation, initData));
        rolesAuthority = RolesAuthority(rolesAuthorityProxy);

        // grant fund admin capabilities
        vm.startPrank(charlie);
        rolesAuthority.setUserRole(address(this), Role.System_FundAdmin, true);
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setUserRole.selector, true
        );
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setUserRoleBroadcast.selector, true
        );
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setUserRoleBatch.selector, true
        );
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setUserRoleBatchBroadcast.selector, true
        );
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setRoleCapability.selector, true
        );
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setPublicCapability.selector, true
        );
        rolesAuthority.setRoleCapability(Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.pause.selector, true);
        vm.stopPrank();

        // make sure timestamp is not 0
        vm.warp(0xffff);
    }
}
