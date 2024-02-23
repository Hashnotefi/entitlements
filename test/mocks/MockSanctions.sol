// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ISanctions} from "../../src/interfaces/ISanctions.sol";

contract MockSanctions is ISanctions {
    mapping(address => bool) public sanctionedList;

    function isSanctioned(address _subAccount) external view returns (bool) {
        return sanctionedList[_subAccount];
    }

    function setSanctioned(address _subAccount, bool access) external {
        sanctionedList[_subAccount] = access;
    }
}
