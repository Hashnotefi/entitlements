// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ISanctions} from "../interfaces/ISanctions.sol";

import "../config/errors.sol";

contract Sanctions is ISanctions {
    address public owner;
    mapping(address => bool) public sanctionedList;

    constructor(address _owner) {
        if (_owner == address(0)) revert BadAddress();

        owner = _owner;
    }

    function transferOwnership(address _owner) external {
        if (msg.sender != owner) revert Unauthorized();

        owner = _owner;
    }

    function isSanctioned(address _subAccount) external view returns (bool) {
        return sanctionedList[_subAccount];
    }

    function setSanctioned(address _subAccount, bool access) external {
        if (msg.sender != owner) revert Unauthorized();

        sanctionedList[_subAccount] = access;
    }
}
