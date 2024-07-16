// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "openzeppelin/proxy/utils/Initializable.sol";

import {IAxelarGateway} from "axelar/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "axelar/interfaces/IAxelarGasService.sol";

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

    IAxelarGateway public immutable gateway;
    IAxelarGasService public immutable gasService;

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

    constructor(address _sanctions, address _gateway, address _gasReceiver) {
        if (_sanctions == address(0)) revert BadAddress();
        if (_gateway == address(0)) revert BadAddress();
        if (_gasReceiver == address(0)) revert BadAddress();

        sanctions = ISanctions(_sanctions);
        gasService = IAxelarGasService(_gasReceiver);
        gateway = IAxelarGateway(_gateway);
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

    function doesUserHaveRole(address user, Role role) public view virtual returns (bool) {
        if (_paused) revert Unauthorized();

        if (uint8(role) <= uint8(Role.Investor_Reserve5)) {
            if (sanctions.isSanctioned(user)) return false;
        }

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

    function _setPublicCapability(address target, bytes4 functionSig, bool enabled) internal virtual {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function _setRoleCapability(Role role, address target, bytes4 functionSig, bool enabled) internal virtual {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << uint8(role));
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << uint8(role));
        }

        emit RoleCapabilityUpdated(uint8(role), target, functionSig, enabled);
    }

    function setPublicCapability(address target, bytes4 functionSig, bool enabled) public virtual {
        _isOwner();
        _setPublicCapability(target, functionSig, enabled);
    }

    function setRoleCapability(Role role, address target, bytes4 functionSig, bool enabled) public virtual {
        _isOwner();
        _setRoleCapability(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _setUserRole(address user, Role role, bool enabled) internal {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << uint8(role));
        } else {
            getUserRoles[user] &= ~bytes32(1 << uint8(role));
        }

        emit UserRoleUpdated(user, uint8(role), enabled);
    }

    function setUserRole(address user, Role role, bool enabled) public virtual {
        _isOwner();
        _setUserRole(user, role, enabled);
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
