// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {RolesAuthority} from "./RolesAuthority.sol";

import {IAxelarGateway} from "axelar/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelar/interfaces/IAxelarGasService.sol";

import "../config/enums.sol";
import "../config/errors.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author dsshap (Hashnote)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthoritySatellite is RolesAuthority {
    /*///////////////////////////////////////////////////////////////
                         Immutables
    //////////////////////////////////////////////////////////////*/

    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/


    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _sanctions, address _gateway, address _gasReceiver) RolesAuthority(_sanctions, _gateway) {
        if (_gateway == address(0)) revert BadAddress();
        if (_gasReceiver == address(0)) revert BadAddress();

        gasService = IAxelarGasService(_gasReceiver);
        gateway = IAxelarGateway(_gateway);
    }

    /*//////////////////////////////////////////////////////////////
                        MULTI-CHAIN EXECUTION LOGIC
    //////////////////////////////////////////////////////////////*/
    function execute(bytes32 _commandId, string calldata _chain, string calldata _address, bytes calldata _payload) external {
        bytes32 payloadHash = keccak256(_payload);
        if (!gateway.validateContractCall(_commandId, _chain, _address, payloadHash)) {
            revert NotPermissioned();
        }

        // Decode the payload to get the function signature and data
        (bytes4 signature, bytes memory data) = abi.decode(_payload, (bytes4, bytes));

        // Decode the data and call the appropriate function based on the signature
        if (signature == this.setUserRole.selector) {
            (address user, Role role, bool enabled) = abi.decode(data, (address, Role, bool));

            _setUserRole(user, role, enabled);
        } else if (signature == this.setRoleCapability.selector) {
            (Role role, address target, bytes4 functionSig, bool enabled) = abi.decode(data, (Role, address, bytes4, bool));

            _setRoleCapability(role, target, functionSig, enabled);
        } else {
            (address target, bytes4 functionSig, bool enabled) = abi.decode(data, (address, bytes4, bool));

            _setPublicCapability(target, functionSig, enabled);
        }
    }

    // TODO: maybe think of a better way to handle broadcasting different functions
    function broadcast(
        bytes4 _functionSignature,
        bytes calldata _payload,
        string[] calldata _chains,
        string[] calldata _addresses
    ) external payable {
        _isOwner();

        if (msg.value == 0) revert InsufficientGas();

        // Encode the payload
        bytes memory payload = abi.encode(_functionSignature, _payload);

        for (uint256 i = 0; i < _chains.length;) {
            gasService.payNativeGasForContractCall{value: msg.value}(
                address(this), _chains[i], _addresses[i], payload, msg.sender
            );
            gateway.callContract(_chains[i], _addresses[i], payload);

            unchecked {
                ++i;
            }
        }
    }
}
