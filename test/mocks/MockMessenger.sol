// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IAxelarMessenger} from "../../src/interfaces/IAxelarMessenger.sol";

contract MockMessenger is IAxelarMessenger {
    function broadcast(bytes calldata payload) external view {}
}
