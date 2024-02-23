// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BaseFixture} from "../fixtures/BaseFixture.t.sol";
import {Role} from "../../src/config/enums.sol";

import "../../src/config/errors.sol";

contract SanctionsTest is BaseFixture {
    Role role;

    function setUp() public {
        role = Role(0);
        rolesAuthority.setUserRole(address(0xBEEF), role, true);
        sanctions.setSanctioned(address(0xBEEF), true);
    }

    function testCannotGetUserRole() public {
        assertFalse(rolesAuthority.doesUserHaveRole(address(0xBEEF), role));
    }

    function testCannotCall() public {
        rolesAuthority.setRoleCapability(role, address(0xCAFE), 0xBEEFCAFE, true);

        assertFalse(rolesAuthority.canCall(address(0xBEEF), address(0xCAFE), 0xBEEFCAFE));
    }
}
