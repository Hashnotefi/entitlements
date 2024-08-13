// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {RolesAuthority, BaseFixture} from "../fixtures/BaseFixture.t.sol";

import {Role} from "../../src/config/enums.sol";
import {Unauthorized, InvalidArrayLength} from "../../src/config/errors.sol";

contract RolesAuthorityTransferOwnershipTest is BaseFixture {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    function testTransferOwnership() public {
        assertEq(rolesAuthority.owner(), charlie);

        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(charlie, address(0xBBBB));

        vm.prank(charlie);
        rolesAuthority.transferOwnership(address(0xBBBB));

        assertEq(rolesAuthority.owner(), address(0xBBBB));
    }

    function testRevertsTransferOwnershipNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.transferOwnership(address(0xBBBB));
    }
}

contract RolesAuthorityRoleCapabilityTest is BaseFixture {
    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    function setUp() public {
        role = Role(0);
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

    function testCanCallPublicCapability() public {
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, false);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));
    }

    function testFundAdminCannotSetFundAdminCapability() public {
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setRoleCapability(Role.System_FundAdmin, TARGET, FUNCTION_SIG, true);
    }

    function testOwnerCanSetFundAdminCapability() public {
        vm.expectEmit(true, true, true, true);
        emit RoleCapabilityUpdated(uint8(Role.System_FundAdmin), TARGET, FUNCTION_SIG, true);

        vm.prank(charlie);
        rolesAuthority.setRoleCapability(Role.System_FundAdmin, TARGET, FUNCTION_SIG, true);
    }

    function testCannotSetRoleCapabilityNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
    }

    function testCannotSetRoleCapabilityNoCapability() public {
        vm.prank(charlie);
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setRoleCapability.selector, false
        );

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
    }

    function testCannotSetPublicCapabilityNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, true);
    }

    function testCannotSetPublicCapabilityNoCapability() public {
        vm.prank(charlie);
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setPublicCapability.selector, false
        );

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setPublicCapability(TARGET, FUNCTION_SIG, true);
    }

    function testCanCallWithAuthorizedRole() public {
        // give role and check that user can't call without capability
        rolesAuthority.setUserRole(USER, role, true);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        // give capability and check that user can call
        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        // remove capability and check that user can't call anymore
        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, false);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));
    }
}

contract RolesAuthoritySetRoleTest is BaseFixture {
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

    function testBroadcasts() public {
        vm.expectEmit(true, true, true, true);
        emit Broadcast(abi.encodeWithSelector(RolesAuthority.setUserRole.selector, USER, uint8(role), true));

        vm.recordLogs();

        rolesAuthority.setUserRoleBroadcast(USER, role, true);

        assertEq(vm.getRecordedLogs().length, 2);
    }

    function testDoesNotCallBroadcastIfRoleIsSystem() public {
        role = Role.Custodian_Centralized;
        assertGt(uint8(role), uint8(Role.Investor_Reserve5));

        vm.expectEmit(false, false, false, false);
        emit UserRoleUpdated(USER, uint8(role), true);

        vm.recordLogs();

        rolesAuthority.setUserRole(USER, role, true);

        assertEq(vm.getRecordedLogs().length, 1);
    }

    function testOwnerCanAddFundAdmin() public {
        vm.expectEmit(true, true, true, true);
        emit UserRoleUpdated(USER, uint8(Role.System_FundAdmin), true);

        vm.prank(charlie);
        rolesAuthority.setUserRole(USER, Role.System_FundAdmin, true);
    }

    function testCanCallWithAuthorizedRole() public {
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        // give role and check that user can't call without capability
        rolesAuthority.setUserRole(USER, role, true);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        // give capability and check that user can call
        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);
        assertTrue(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));

        // check that if role is revoked, user can't call it anymore
        rolesAuthority.setUserRole(USER, role, false);
        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));
    }

    function testCannotSetUserRoleNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRole(USER, role, true);
    }

    function testFundAdminCannotAddFundAdmin() public {
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRole(USER, Role.System_FundAdmin, true);
    }

    function testCannotSetUserRoleNoCapability() public {
        vm.prank(charlie);
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setUserRole.selector, false
        );

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRole(USER, role, true);
    }
}

contract RolesAuthoritySetUserRoleBatchTest is BaseFixture {
    address[] users;
    Role[] roles;
    bool[] enabled;

    function setUp() public {
        users = new address[](2);
        roles = new Role[](2);
        enabled = new bool[](2);

        users[0] = address(0x1111);
        roles[0] = Role(0);
        enabled[0] = true;

        users[1] = address(0x1111);
        roles[1] = Role(1);
        enabled[1] = true;
    }

    function testSetUserRoleBatch() public {
        vm.expectEmit(true, true, true, true);
        emit UserRoleUpdated(users[0], uint8(roles[0]), true);

        vm.expectEmit(true, true, true, true);
        emit UserRoleUpdated(users[1], uint8(roles[1]), true);

        vm.recordLogs();

        rolesAuthority.setUserRoleBatch(users, roles, enabled);

        assertTrue(rolesAuthority.doesUserHaveRole(users[0], roles[0]));
        assertTrue(rolesAuthority.doesUserHaveRole(users[1], roles[1]));

        assertEq(vm.getRecordedLogs().length, 2);
    }

    function testBatchBroadcasts() public {
        vm.expectEmit(true, true, true, true);
        emit Broadcast(abi.encodeWithSelector(RolesAuthority.setUserRoleBatch.selector, users, roles, enabled));

        vm.recordLogs();

        rolesAuthority.setUserRoleBatchBroadcast(users, roles, enabled);

        // logs + broadcast should be emitted
        assertEq(vm.getRecordedLogs().length, 3);
    }

    function testRevertsIfArrayLengthsDoNotMatch() public {
        users = new address[](1);

        vm.expectRevert(InvalidArrayLength.selector);
        rolesAuthority.setUserRoleBatch(users, roles, enabled);
    }

    function testCannotCallNotFundAdmin() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRoleBatch(users, roles, enabled);
    }

    function testCannotCallByOwner() public {
        vm.prank(charlie);
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRoleBatch(users, roles, enabled);
    }

    function testCannotSetUserRoleBatchNoCapability() public {
        vm.prank(charlie);
        rolesAuthority.setRoleCapability(
            Role.System_FundAdmin, address(rolesAuthority), rolesAuthority.setUserRoleBatch.selector, false
        );

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRoleBatch(users, roles, enabled);
    }
}
