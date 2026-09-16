// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRoles {
    // =============================================================
    //                         SETUP
    // =============================================================

    function setUp(bytes calldata initParams) external;

    // =============================================================
    //                    ROLE MANAGEMENT
    // =============================================================

    function assignRoles(
        address module,
        bytes32[] calldata roleKeys,
        bool[] calldata memberOf
    ) external;

    function setDefaultRole(
        address module,
        bytes32 roleKey
    ) external;


    // =============================================================
    //                    TARGET PERMISSIONS
    // =============================================================

    function allowTarget(
        bytes32 roleKey,
        address targetAddress,
        uint8 options
    ) external;

    function scopeTarget(
        bytes32 roleKey,
        address targetAddress
    ) external;

    function revokeTarget(
        bytes32 roleKey,
        address targetAddress
    ) external;

    function setTarget(
        address newTarget) 
        external;


    // =============================================================
    //                   FUNCTION PERMISSIONS
    // =============================================================

    function allowFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector,
        uint8 options
    ) external;

    function scopeFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector,
        ConditionFlat[] calldata conditions,
        uint8 options
    ) external;

    function revokeFunction(
        bytes32 roleKey,
        address targetAddress,
        bytes4 selector
    ) external;


    // =============================================================
    //                     EXECUTION
    // =============================================================

    function execTransactionWithRole(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation,
        bytes32 roleKey,
        bool shouldRevert
    ) external returns (bool success);


    // =============================================================
    //                         VIEWS
    // =============================================================

    function owner() external view returns (address);

    function avatar() external view returns (address);

    function target() external view returns (address);

    function isModuleEnabled(
        address module
    ) external view returns (bool);
    

    // =============================================================
    //                       STRUCTURES
    // =============================================================

    struct ConditionFlat {
        uint8 parent;
        uint8 paramType;
        uint8 operator;
        bytes compValue;
    }
}