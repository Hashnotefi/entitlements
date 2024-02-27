// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BaseFixture} from "../fixtures/BaseFixture.t.sol";

import {Role} from "../../src/config/enums.sol";
import {Unauthorized} from "../../src/config/errors.sol";

contract RolesAuthorityTransferOwnershipTest is BaseFixture {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    function testTransferOwnership() public {
        assertEq(rolesAuthority.owner(), address(this));

        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(address(this), address(0xBBBB));

        rolesAuthority.transferOwnership(address(0xBBBB));

        assertEq(rolesAuthority.owner(), address(0xBBBB));
    }

    function testRevertsTransferOwnershipNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.transferOwnership(address(0xBBBB));
    }
}

contract RolesAuthorityTest is BaseFixture {
    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    function setUp() public {
        role = Role(0);
    }

    function testSetRoles() public {
        assertFalse(rolesAuthority.doesUserHaveRole(USER, role));

        vm.expectEmit(true, true, true, true);
        emit UserRoleUpdated(USER, uint8(role), true);

        rolesAuthority.setUserRole(USER, role, true);
        assertTrue(rolesAuthority.doesUserHaveRole(USER, role));

        vm.expectEmit(true, true, true, true);
        emit UserRoleUpdated(USER, uint8(role), false);

        rolesAuthority.setUserRole(USER, role, false);
        assertFalse(rolesAuthority.doesUserHaveRole(USER, role));
    }

    function testSetRoleCapabilities() public {
        assertFalse(rolesAuthority.doesRoleHaveCapability(role, TARGET, FUNCTION_SIG));

        vm.expectEmit(true, true, true, true);
        emit RoleCapabilityUpdated(uint8(role), TARGET, FUNCTION_SIG, true);

        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.doesRoleHaveCapability(role, TARGET, FUNCTION_SIG));

        vm.expectEmit(true, true, true, true);
        emit RoleCapabilityUpdated(uint8(role), TARGET, FUNCTION_SIG, false);

        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, false);
        assertFalse(rolesAuthority.doesRoleHaveCapability(role, TARGET, FUNCTION_SIG));
    }

    function testSetPublicCapabilities() public {
        assertFalse(rolesAuthority.isCapabilityPublic(TARGET, FUNCTION_SIG));

        vm.expectEmit(true, true, true, true);
        emit PublicCapabilityUpdated(TARGET, FUNCTION_SIG, true);

        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.isCapabilityPublic(TARGET, FUNCTION_SIG));

        vm.expectEmit(true, true, true, true);
        emit PublicCapabilityUpdated(TARGET, FUNCTION_SIG, false);

        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, false);
        assertFalse(rolesAuthority.isCapabilityPublic(TARGET, FUNCTION_SIG));
    }

    function testCanCallWithAuthorizedRole() public {
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setUserRole(USER, role, true);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, false);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setUserRole(USER, role, false);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));
    }

    function testCanCallPublicCapability() public {
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, false);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));
    }

    function testCannotSetRoleCapabilityNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
    }

    function testCannotSetPublicCapabilityNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, true);
    }

    function testCannotSetUserRoleNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRole(USER, role, true);
    }
}
