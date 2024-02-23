// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {BaseFixture} from "../fixtures/BaseFixture.t.sol";

import {MockUpgrade} from "../mocks/MockUpgrade.sol";

import "../../src/config/errors.sol";

contract UpgradesTest is BaseFixture {
    function testCannotUpgradeFromNonOwner() public {
        vm.prank(alice);
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.upgradeToAndCall(address(0), new bytes(0));
    }

    function testUpgrade() public {
        MockUpgrade v2 = new MockUpgrade();

        rolesAuthority.upgradeToAndCall(address(v2), new bytes(0));

        vm.expectRevert("cannot upgrade from v2");
        rolesAuthority.upgradeToAndCall(address(v2), new bytes(0));
    }
}
