// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {RolesAuthority} from "../../src/core/RolesAuthority.sol";
import {RolesAuthorityProxy} from "../../src/core/RolesAuthorityProxy.sol";

import {MockSanctions} from "../mocks/MockSanctions.sol";

/**
 * helper contract with shared logic for fixtures to inherit
 */
abstract contract BaseFixture is Test {
    RolesAuthority public rolesAuthority;
    MockSanctions internal sanctions;

    address public alice;
    address public charlie;
    address public bob;

    constructor() {
        charlie = address(0xcccc);
        vm.label(charlie, "Charlie");

        bob = address(0xb00b);
        vm.label(bob, "Bob");

        alice = address(0xaaaa);
        vm.label(alice, "Alice");

        sanctions = new MockSanctions();

        address implementation = address(new RolesAuthority());
        bytes memory initData = abi.encodeWithSelector(RolesAuthority.initialize.selector, address(this), address(sanctions));
        address rolesAuthorityProxy = address(new RolesAuthorityProxy(implementation, initData));
        rolesAuthority = RolesAuthority(rolesAuthorityProxy);


        // make sure timestamp is not 0
        vm.warp(0xffff);
    }
}
