// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseFixture} from "../fixtures/BaseFixture.t.sol";

import {Role} from "../../src/config/enums.sol";
import {Unauthorized} from "../../src/config/errors.sol";

contract PauserTest is BaseFixture {
    event Paused(address account);

    event Unpaused(address account);

    function setUp() public {
        role = Role(0);
        rolesAuthority.setUserRole(USER, role, true);
        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
    }

    function testPause() public {
        vm.expectEmit(true, true, true, true);
        emit Paused(address(this));

        rolesAuthority.pause();
    }

    function testUnpause1() public {
        rolesAuthority.pause();

        vm.expectEmit(true, true, true, true);
        emit Unpaused(charlie);

        vm.prank(charlie);
        rolesAuthority.unpause();
    }

    function testPauseDisablesDoesUserHaveRole() public {
        rolesAuthority.pause();

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.doesUserHaveRole(USER, role);
    }

    function testPauseDisablesDoesRoleHaveCapability() public {
        rolesAuthority.pause();

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.doesRoleHaveCapability(role, USER, FUNCTION_SIG);
    }

    function testPauseDisablesCanCall() public {
        rolesAuthority.pause();

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG);
    }

    function testUnpauseEnablesDoesUserHaveRole() public {
        rolesAuthority.pause();

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.doesUserHaveRole(USER, role);

        vm.prank(charlie);
        rolesAuthority.unpause();
        assertTrue(rolesAuthority.doesUserHaveRole(USER, role));
    }

    function testUnpauseEnablesDoesRoleHaveCapability() public {
        rolesAuthority.pause();

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.doesRoleHaveCapability(role, TARGET, FUNCTION_SIG);

        vm.prank(charlie);
        rolesAuthority.unpause();
        assertTrue(rolesAuthority.doesRoleHaveCapability(role, TARGET, FUNCTION_SIG));
    }

    function testUnpauseEnablesCanCall() public {
        rolesAuthority.pause();

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG);

        vm.prank(charlie);
        rolesAuthority.unpause();
        assertTrue(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));
    }

    function testRevertsOnPauseFromNonOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.pause();
    }

    function testRevertsOnUnpauseFromNonOwner() public {
        rolesAuthority.pause();

        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.unpause();
    }
}
