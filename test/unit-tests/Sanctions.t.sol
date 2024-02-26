// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {BaseFixture} from "../fixtures/BaseFixture.t.sol";

import {Role} from "../../src/config/enums.sol";
import {BadAddress, Unauthorized} from "../../src/config/errors.sol";

contract SanctionsTest is BaseFixture {
    event SanctionsUpdated(address oldSanctions, address newSanctions);

    function setUp() public {
        role = Role(0);
        rolesAuthority.setUserRole(USER, role, true);
        sanctions.setSanctioned(USER, true);
    }

    function testSetSanctions() public {
        assertEq(rolesAuthority.sanctions(), address(sanctions));

        vm.expectEmit(true, true, true, true);
        emit SanctionsUpdated(address(sanctions), address(0xBBBB));

        rolesAuthority.setSanctions(address(0xBBBB));

        assertEq(rolesAuthority.sanctions(), address(0xBBBB));
    }

    function testRevertsSetSanctionsToZeroAddress() public {
        vm.expectRevert(BadAddress.selector);
        rolesAuthority.setSanctions(address(0));
    }

    function testRevertsSetSanctionsNotOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.setSanctions(address(0xBBBB));
    }

    function testCannotGetUserRole() public {
        assertTrue(sanctions.isSanctioned(USER));

        assertFalse(rolesAuthority.doesUserHaveRole(USER, role));
    }

    function testCannotCall() public {
        assertTrue(sanctions.isSanctioned(USER));

        rolesAuthority.setRoleCapability(role, TARGET, FUNCTION_SIG, true);

        assertFalse(rolesAuthority.canCall(USER, TARGET, FUNCTION_SIG));
    }
}
