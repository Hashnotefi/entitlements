// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {RolesAuthority} from "../../src/core/RolesAuthority.sol";
import {RolesAuthorityProxy} from "../../src/core/RolesAuthorityProxy.sol";
import {Role} from "../../src/config/enums.sol";

import {MockSanctions} from "../mocks/MockSanctions.sol";

/**
 * helper contract with shared logic for fixtures to inherit
 */
abstract contract BaseFixture is Test {
    RolesAuthority public rolesAuthority;
    MockSanctions internal sanctions;

    Role internal role;

    address public alice;
    address public charlie;
    address public bob;

    // constants for testing
    address internal constant USER = address(0xBEEF);
    address internal constant TARGET = address(0xCAFE);

    bytes4 internal constant FUNCTION_SIG = bytes4(0xBEEFCAFE);

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

        // TODO: change to valid addresses
        address implementation = address(new RolesAuthority(address(sanctions), address(0x1), address(0x1)));
        bytes memory initData = abi.encodeWithSelector(RolesAuthority.initialize.selector, address(this));
        address rolesAuthorityProxy = address(new RolesAuthorityProxy(implementation, initData));
        rolesAuthority = RolesAuthority(rolesAuthorityProxy);

        // make sure timestamp is not 0
        vm.warp(0xffff);
    }
}
