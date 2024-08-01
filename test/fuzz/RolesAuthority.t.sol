// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BaseFixture} from "../fixtures/BaseFixture.t.sol";

import {Role} from "../../src/config/enums.sol";
import {Unauthorized} from "../../src/config/errors.sol";

contract RolesAuthorityTest is BaseFixture {
    function setUp() public {
        role = Role(0);
    }

    function testSetRoles(address _user, uint8 _role) public {
        vm.assume(_role < 22 && _role != uint8(Role.System_FundAdmin));
        vm.assume(_user != address(0));

        assertFalse(rolesAuthority.doesUserHaveRole(_user, Role(_role)));

        rolesAuthority.setUserRole(_user, Role(_role), true);
        assertTrue(rolesAuthority.doesUserHaveRole(_user, Role(_role)));

        rolesAuthority.setUserRole(_user, Role(_role), false);
        assertFalse(rolesAuthority.doesUserHaveRole(_user, Role(_role)));
    }

    function testSetRoleCapabilities(uint8 _role, address _target, bytes4 _functionSig) public {
        vm.assume(_role < 22 && _role != uint8(Role.System_FundAdmin));

        assertFalse(rolesAuthority.doesRoleHaveCapability(Role(_role), _target, _functionSig));

        rolesAuthority.setRoleCapability(Role(_role), _target, _functionSig, true);
        assertTrue(rolesAuthority.doesRoleHaveCapability(Role(_role), _target, _functionSig));

        rolesAuthority.setRoleCapability(Role(_role), _target, _functionSig, false);
        assertFalse(rolesAuthority.doesRoleHaveCapability(Role(_role), _target, _functionSig));
    }

    function testSetPublicCapabilities(address target, bytes4 functionSig) public {
        assertFalse(rolesAuthority.isCapabilityPublic(target, functionSig));

        rolesAuthority.setPublicCapability(target, functionSig, true);
        assertTrue(rolesAuthority.isCapabilityPublic(target, functionSig));

        rolesAuthority.setPublicCapability(target, functionSig, false);
        assertFalse(rolesAuthority.isCapabilityPublic(target, functionSig));
    }

    function testCanCallWithAuthorizedRole(address _user, uint8 _role, address _target, bytes4 _functionSig) public {
        vm.assume(_role < 22 && _role != uint8(Role.System_FundAdmin));
        vm.assume(_user != address(0));

        assertFalse(rolesAuthority.canCall(_user, _target, _functionSig));

        rolesAuthority.setUserRole(_user, Role(_role), true);
        assertFalse(rolesAuthority.canCall(_user, _target, _functionSig));

        rolesAuthority.setRoleCapability(Role(_role), _target, _functionSig, true);
        assertTrue(rolesAuthority.canCall(_user, _target, _functionSig));

        rolesAuthority.setRoleCapability(Role(_role), _target, _functionSig, false);
        assertFalse(rolesAuthority.canCall(_user, _target, _functionSig));

        rolesAuthority.setRoleCapability(Role(_role), _target, _functionSig, true);
        assertTrue(rolesAuthority.canCall(_user, _target, _functionSig));

        rolesAuthority.setUserRole(_user, Role(_role), false);
        assertFalse(rolesAuthority.canCall(_user, _target, _functionSig));
    }

    function testCanCallPublicCapability(address user, address target, bytes4 functionSig) public {
        vm.assume(user != address(0));

        assertFalse(rolesAuthority.canCall(user, target, functionSig));

        rolesAuthority.setPublicCapability(target, functionSig, true);
        assertTrue(rolesAuthority.canCall(user, target, functionSig));

        rolesAuthority.setPublicCapability(target, functionSig, false);
        assertFalse(rolesAuthority.canCall(user, target, functionSig));
    }

    function testSetUserRolesBatchRevertsOnSystemRole(uint8 _role) public {
        vm.assume(_role > uint8(Role.Investor_Reserve5) && _role < 22);

        address[] memory users = new address[](1);
        Role[] memory roles = new Role[](1);
        bool[] memory enabled = new bool[](1);

        users[0] = USER;
        roles[0] = Role(_role);
        enabled[0] = true;

        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setUserRoleBatch(users, roles, enabled);
    }
}
