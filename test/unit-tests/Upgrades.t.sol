// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";

import {RolesAuthority} from "../../src/core/RolesAuthority.sol";
import {RolesAuthorityProxy} from "../../src/core/RolesAuthorityProxy.sol";
import {Unauthorized} from "../../src/config/errors.sol";

import {MockUpgrade} from "../mocks/MockUpgrade.sol";

contract UpgradesTest is Test {
    address public constant SANCTIONS_ADDR = address(0xCCCC);

    RolesAuthority public rolesAuthority;
    RolesAuthority public rolesAuthorityImplementation;

    function setUp() public {
        rolesAuthorityImplementation = new RolesAuthority();
        bytes memory data = abi.encodeWithSelector(RolesAuthority.initialize.selector, address(this), SANCTIONS_ADDR);

        rolesAuthority = RolesAuthority(address(new RolesAuthorityProxy(address(rolesAuthorityImplementation), data)));
    }

    function testImplementationContractOwnerIsZero() public {
        assertEq(rolesAuthorityImplementation.owner(), address(0));
    }

    function testProxyOwnerIsSelf() public {
        assertEq(rolesAuthority.owner(), address(this));
    }

    function testProxyIsInitialized() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        rolesAuthority.initialize(address(this), SANCTIONS_ADDR);
    }

    function testUpgrade() public {
        MockUpgrade v2 = new MockUpgrade(2);

        // RolesAuthority v1 does not have a `version` function yet
        vm.expectRevert( /* EvmError: Revert */ );
        MockUpgrade(address(rolesAuthority)).version();

        rolesAuthority.upgradeToAndCall(address(v2), new bytes(0));

        // now the version function is available in the upgraded contract and returns 2
        assertEq(MockUpgrade(address(rolesAuthority)).version(), 2);
    }

    function testCannotUpgradeToZeroAddress() public {
        vm.expectRevert( /* EvmError: Revert */ );
        rolesAuthority.upgradeToAndCall(address(0), new bytes(0));
    }

    function testCannotUpgradeFromNonOwner() public {
        vm.prank(address(0xAAAA));
        vm.expectRevert(Unauthorized.selector);
        rolesAuthority.upgradeToAndCall(address(0), new bytes(0));
    }

    function testCannotUpgradeTov3() public {
        MockUpgrade v2 = new MockUpgrade(2);
        MockUpgrade v3 = new MockUpgrade(3);

        rolesAuthority.upgradeToAndCall(address(v2), new bytes(0));

        vm.expectRevert("cannot upgrade from v2");
        rolesAuthority.upgradeToAndCall(address(v3), new bytes(0));
    }
}
