// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

contract MockSimpleSettlementUpgrade is UUPSUpgradeable {
    function currentVersion() external pure returns (uint256) {
        return 4;
    }

    // add a function prefixed with test here so forge coverage will ignore this file
    function test() public {}

    // cannot upgrade from this version
    function _authorizeUpgrade(address /*newImplementation*/ ) internal pure override {
        revert("cannot upgrade from v2");
    }
}
