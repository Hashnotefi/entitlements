// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

contract MockUpgrade is UUPSUpgradeable {
    // cannot upgrade from this version
    function _authorizeUpgrade(address /*newImplementation*/ ) internal pure override {
        revert("cannot upgrade from v2");
    }
}
