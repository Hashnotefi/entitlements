// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {RolesAuthority} from "../../src/core/RolesAuthority.sol";
import {RolesAuthorityProxy} from "../../src/core/RolesAuthorityProxy.sol";
import {Role} from "../../src/config/enums.sol";

import {MockSanctions} from "../mocks/MockSanctions.sol";
import {MockMessenger} from "../mocks/MockMessenger.sol";

/**
 * helper contract with shared logic for fixtures to inherit
 */
abstract contract BaseFixture is Test {
    RolesAuthority public rolesAuthority;
    MockSanctions internal sanctions;
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

        sanctions = new MockSanctions();
        messenger = new MockMessenger();

        address implementation = address(new RolesAuthority(address(sanctions), address(messenger)));
        bytes memory initData = abi.encodeWithSelector(RolesAuthority.initialize.selector, charlie);
        address rolesAuthorityProxy = address(new RolesAuthorityProxy(implementation, initData));
        rolesAuthority = RolesAuthority(rolesAuthorityProxy);

        vm.prank(charlie);
        rolesAuthority.setUserRole(address(this), Role.System_FundAdmin, true);

        // make sure timestamp is not 0
        vm.warp(0xffff);
    }
}
