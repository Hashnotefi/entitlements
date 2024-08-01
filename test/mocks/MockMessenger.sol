// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IAxelarMessenger} from "../../src/interfaces/IAxelarMessenger.sol";

contract MockMessenger is IAxelarMessenger {
    event Broadcast(bytes payload);

    function broadcast(bytes calldata payload) external {
        emit Broadcast(payload);
    }
}
