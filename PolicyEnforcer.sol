// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

//Interfaces

interface IPaymentPolicy {
    function checkPayment(
        address token, 
        address recipient,
        uint256 amount) external view 
        returns (bool allowed, string memory reason
        ); 
    }

interface ISafeModuleExecutor {
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation) external returns (bool success);

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation) external returns (bool success, bytes memory returnData);
    }

contract PolicyEnforcer {

    address public immutable safe;
    address public immutable roles;

    IPaymentPolicy public immutable paymentPolicy;

    bytes4 public constant TRANSFER_SELECTOR = 0xa9059cbb;
    uint8 public constant CALL = 0;

    error OnlyCallOperationAllowed();
    error NativeValueNotAllowed();
    error InvalidCalldataLength();
    error FunctionNotAllowed(bytes4 selector);
    error SafeExecutionFailed();

    event PaymentExecuted(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );

    event PaymentDenied(
        address indexed token,
        address indexed recipient,
        uint256 amount, 
        string reason
    );
    
    modifier onlyRoles() {
        require(msg.sender == roles, "Caller is not the Roles Modifier");
        _;
    }

    constructor(
        address _safe,
        address _roles,
        address _paymentPolicy
    ) {
        require(_safe != address(0), "Invalid Safe");
        require(_roles != address(0), "Invalid Roles");
        require(_paymentPolicy != address(0), "Invalid policy");

        safe = _safe;
        roles = _roles;
        paymentPolicy = IPaymentPolicy(_paymentPolicy);
    }


    function _evaluatePayment (
        address to, 
        uint256 value, 
        bytes calldata data, 
        uint8 operation) internal view returns (bool allowed, 
        address recipient, 
        uint256 amount,
        string memory reason)
    {
    if (operation != CALL) {
        return (false, 
        address(0),
        0,
        "INVALID_OPERATION"
        );
    }

    if (value != 0) {
        return (
            false,
            address(0),
            0,
            "NATIVE_VALUE_NOT_ALLOWED"
            );
        }

// transfer selector: 4 bytes
// recipient:        32 bytes
// amount:           32 bytes

    if (data.length != 68) {
    return (
        false,
        address(0),
        0,
        "INVALID_CALLDATA");
    }

    bytes4 selector;

    assembly{
        selector:= calldataload(data.offset)
    }

    if (selector != TRANSFER_SELECTOR){
    return (
        false,
        address(0),
        0,
        "FUNCTION_NOT_ALLOWED"
        );
    }

    (recipient, amount) = abi.decode(
        data[4:],
        (address, uint256)
    );

    (allowed, reason)= paymentPolicy.checkPayment(to, recipient, amount);
    
    return (
        allowed,
        recipient,
        amount,
        reason
        );
    }

        function execTransactionFromModule(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    )
        external
        onlyRoles
        returns (bool success)
    {
        (
            bool allowed,
            address recipient,
            uint256 amount,
            string memory reason
        ) = _evaluatePayment(
            to,
            value,
            data,
            operation
        );

        /*
         * Expected policy denial:
         * record it, skip Safe execution and return successfully.
         */
        if (!allowed) {
            emit PaymentDenied(
                to,
                recipient,
                amount,
                reason
            );

            return true;
        }

        /*
         * Only approved payments reach the Safe.
         */
        success =
            ISafeModuleExecutor(safe)
                .execTransactionFromModule(
                    to,
                    value,
                    data,
                    operation
                );

        /*
         * This represents an unexpected execution failure,
         * not an expected policy denial.
         */
        if (!success) {
            revert SafeExecutionFailed();
        }

        emit PaymentExecuted(
            to,
            recipient,
            amount
        );

        return true;
    }

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes calldata data,
        uint8 operation
    )
        external
        onlyRoles
        returns (
            bool success,
            bytes memory returnData
        )
    {
        (
            bool allowed,
            address recipient,
            uint256 amount,
            string memory reason
        ) = _evaluatePayment(
            to,
            value,
            data,
            operation
        );

        /*
         * Expected policy denial:
         * preserve the denial event and report that the
         * enforcer handled the request successfully.
         */
        if (!allowed) {
            emit PaymentDenied(
                to,
                recipient,
                amount,
                reason
            );

            return (
                true,
                abi.encode(false, reason)
            );
        }

        /*
         * Only approved payments reach the Safe.
         */
        (success, returnData) =
            ISafeModuleExecutor(safe)
                .execTransactionFromModuleReturnData(
                    to,
                    value,
                    data,
                    operation
                );

        if (!success) {
            revert SafeExecutionFailed();
        }

        emit PaymentExecuted(
            to,
            recipient,
            amount
        );

        return (success, returnData);
    }
}