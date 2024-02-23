// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BaseFixture} from "../fixtures/BaseFixture.t.sol";
import {Role} from "../../src/config/enums.sol";

contract RolesAuthorityTest is BaseFixture {
    Role role;

    function setUp() public {
        role = Role(0);
    }

    function testSetRoles() public {
        assertFalse(rolesAuthority.doesUserHaveRole(address(0xBEEF), role));

        rolesAuthority.setUserRole(address(0xBEEF), role, true);
        assertTrue(rolesAuthority.doesUserHaveRole(address(0xBEEF), role));

        rolesAuthority.setUserRole(address(0xBEEF), role, false);
        assertFalse(rolesAuthority.doesUserHaveRole(address(0xBEEF), role));
    }

    function testSetRoleCapabilities() public {
        assertFalse(rolesAuthority.doesRoleHaveCapability(role, address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setRoleCapability(role, address(0xCAFE), 0xBEEFCAFE, true);
        assertTrue(rolesAuthority.doesRoleHaveCapability(role, address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setRoleCapability(role, address(0xCAFE), 0xBEEFCAFE, false);
        assertFalse(rolesAuthority.doesRoleHaveCapability(role, address(0xCAFE), 0xBEEFCAFE));
    }

    function testSetPublicCapabilities() public {
        assertFalse(rolesAuthority.isCapabilityPublic(address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setPublicCapability(address(0xCAFE), 0xBEEFCAFE, true);
        assertTrue(rolesAuthority.isCapabilityPublic(address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setPublicCapability(address(0xCAFE), 0xBEEFCAFE, false);
        assertFalse(rolesAuthority.isCapabilityPublic(address(0xCAFE), 0xBEEFCAFE));
    }

    function testCanCallWithAuthorizedRole() public {
        assertFalse(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setUserRole(address(0xBEEF), role, true);
        assertFalse(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setRoleCapability(role, address(0xCAFE), 0xBEEFCAFE, true);
        assertTrue(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setRoleCapability(role, address(0xCAFE), 0xBEEFCAFE, false);
        assertFalse(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setRoleCapability(role, address(0xCAFE), 0xBEEFCAFE, true);
        assertTrue(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setUserRole(address(0xBEEF), role, false);
        assertFalse(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));
    }

    function testCanCallPublicCapability() public {
        assertFalse(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setPublicCapability(address(0xCAFE), 0xBEEFCAFE, true);
        assertTrue(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));

        rolesAuthority.setPublicCapability(address(0xCAFE), 0xBEEFCAFE, false);
        assertFalse(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));
    }

    function testSetRoles(address _user, uint8 _role) public {
        vm.assume(_role < 22);

        assertFalse(rolesAuthority.doesUserHaveRole(_user, Role(_role)));

        rolesAuthority.setUserRole(_user, Role(_role), true);
        assertTrue(rolesAuthority.doesUserHaveRole(_user, Role(_role)));

        rolesAuthority.setUserRole(_user, Role(_role), false);
        assertFalse(rolesAuthority.doesUserHaveRole(_user, Role(_role)));
    }

    function testSetRoleCapabilities(
        uint8 _role,
        address _target,
        bytes4 _functionSig
    ) public {
        vm.assume(_role < 22);

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

    function testCanCallWithAuthorizedRole(
        address _user,
        uint8 _role,
        address _target,
        bytes4 _functionSig
    ) public {
        vm.assume(_user != address(0));
        vm.assume(_role < 22);

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

    function testCanCallPublicCapability(
        address user,
        address target,
        bytes4 functionSig
    ) public {
        vm.assume(user != address(0));

        assertFalse(rolesAuthority.canCall(user, target, functionSig));

        rolesAuthority.setPublicCapability(target, functionSig, true);
        assertTrue(rolesAuthority.canCall(user, target, functionSig));

        rolesAuthority.setPublicCapability(target, functionSig, false);
        assertFalse(rolesAuthority.canCall(user, target, functionSig));
    }
}
