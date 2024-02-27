// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";

import {IAuthority} from "../interfaces/IAuthority.sol";
import {ISanctions} from "../interfaces/ISanctions.sol";

import "../config/enums.sol";
import "../config/errors.sol";

/// @notice Role based Authority that supports up to 256 roles.
/// @author dsshap (Hashnote)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is IAuthority, Initializable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                         Immutables
    //////////////////////////////////////////////////////////////*/

    ISanctions public immutable sanctions;

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/
    address public owner;

    bool private _paused;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    event Paused(address account);

    event Unpaused(address account);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _sanctions) {
        if (_sanctions == address(0)) revert BadAddress();

        sanctions = ISanctions(_sanctions);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(address _owner) external initializer {
        if (_owner == address(0)) revert BadAddress();

        owner = _owner;
    }

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    // function _sanctioned(address _address) internal view returns (bool) {
    //     if (_address == address(0)) revert BadAddress();

    //     return sanctions != address(0) ? ISanctions(sanctions).isSanctioned(_address) : false;
    // }

    function doesUserHaveRole(address user, Role role) public view virtual returns (bool) {
        if (_paused) revert Unauthorized();
        if (sanctions.isSanctioned(user)) return false;

        return (uint256(getUserRoles[user]) >> uint8(role)) & 1 != 0;
    }

    function doesRoleHaveCapability(Role role, address target, bytes4 functionSig) public view virtual returns (bool) {
        if (_paused) revert Unauthorized();

        return (uint256(getRolesWithCapability[target][functionSig]) >> uint8(role)) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(address user, address target, bytes4 functionSig) public view virtual override returns (bool) {
        if (_paused) revert Unauthorized();
        if (sanctions.isSanctioned(user)) return false;

        return isCapabilityPublic[target][functionSig]
            || bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function _isOwner() internal view {
        if (msg.sender != owner) revert Unauthorized();
    }

    function setPublicCapability(address target, bytes4 functionSig, bool enabled) public virtual {
        _isOwner();

        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(Role role, address target, bytes4 functionSig, bool enabled) public virtual {
        _isOwner();

        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << uint8(role));
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << uint8(role));
        }

        emit RoleCapabilityUpdated(uint8(role), target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(address user, Role role, bool enabled) public virtual {
        _isOwner();

        if (enabled) {
            getUserRoles[user] |= bytes32(1 << uint8(role));
        } else {
            getUserRoles[user] &= ~bytes32(1 << uint8(role));
        }

        emit UserRoleUpdated(user, uint8(role), enabled);
    }

    /*//////////////////////////////////////////////////////////////
                            PAUSE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Pauses whitelist
     * @dev reverts on any check of permissions preventing any movement of funds
     *      between vault, auction, and option protocol
     */
    function pause() public {
        _isOwner();

        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Unpauses whitelist
     */
    function unpause() public {
        _isOwner();

        _paused = false;
        emit Unpaused(msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public {
        _isOwner();

        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(address /*newImplementation*/ ) internal view override {
        _isOwner();
    }
}
