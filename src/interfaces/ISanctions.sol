// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISanctions {
    function isSanctioned(address _address) external view returns (bool);
}