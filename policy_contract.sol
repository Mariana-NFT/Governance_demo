// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PaymentPolicy {
    address public immutable safe;
    address public enforcer;

    address public permittedToken;
    uint256 public maxAmount;

    mapping(address => bool) public allowedRecipients;

    // Events
    event EnforcerUpdated(
        address indexed previousEnforcer,
        address indexed newEnforcer
    );

    event RecipientAllowlisted(
        address indexed recipient,
        bool allowed
    );

    event PolicyTermsUpdated(
        address indexed permittedToken,
        uint256 maxAmount,
        address indexed updatedBy
    );

    modifier onlySafe() {
        require(msg.sender == safe, "Caller is not the Safe");
        _;
    }

    modifier onlyEnforcer() {
        require(msg.sender == enforcer, "Caller is not the enforcer");
        _;
    }

    constructor(address _safe) {
        require(_safe != address(0), "Invalid Safe address");
        safe = _safe;
    }

    function setEnforcer(address newEnforcer) external onlySafe {
        require(newEnforcer != address(0), "Invalid enforcer");

        emit EnforcerUpdated(enforcer, newEnforcer);
        enforcer = newEnforcer;
    }

    function setRecipientAllowed(
        address recipient,
        bool allowed
    ) external onlySafe {
        require(recipient != address(0), "Invalid recipient");

        allowedRecipients[recipient] = allowed;

        emit RecipientAllowlisted(recipient, allowed);
    }

    function setPolicyTerms(
        address token,
        uint256 amount
    ) external onlySafe {
        require(token != address(0), "Invalid token");
        require(amount > 0, "Amount must be positive");

        permittedToken = token;
        maxAmount = amount;

        emit PolicyTermsUpdated(token, amount, msg.sender);
    }

    bool public paymentsEnabled;
    
    event PaymentsEnabledUpdated(bool enabled);

    function setPaymentsEnabled (
        bool enabled 
    ) external onlySafe{
        paymentsEnabled = enabled;
        emit PaymentsEnabledUpdated(enabled);
    }

    function checkPayment(
        address token,
        address recipient,
        uint256 amount
    ) external view onlyEnforcer
    returns (bool allowed,
    string memory reason) 
    
    {
        if (!paymentsEnabled) {
            return (false, "PAYMENTS_DISABLED");
        }

        if (token != permittedToken) {
            return (false,"TokenNotPermitted");
        }

        if (amount == 0) {
            return (false, "INVALID_AMOUNT");
        }

        if (amount > maxAmount) {
            return (false, "AMOUNT_EXCEEDS_LIMIT");
        }

        if (!allowedRecipients[recipient]) {
            return (false, "RECIPIENT_NOT_ALLOWED");
        }

        return (true, "");

    }
}