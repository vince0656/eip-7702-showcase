// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

abstract contract Transactions {
    
    error FailedToExecuteTransaction();
    error NoTransactions();
    error ReentrancyDetected();

    struct Transaction {
        address target; // Address of the smart contract that will be executed
        uint256 value;  // Any msg.value that needs to be sent to the target
        bytes callData; // The raw encoded function call and data
    }

    /// @dev Use a transient storage variable for reentrancy protection
    bool transient executingTransactions;

    /// @dev Reusable logic for executing any EVM transaction with built in re-entrancy
    function executeTransaction(Transaction memory transaction, bool attachValue) internal {
        // Ensure we have reentrancy protection
        if (executingTransactions) revert ReentrancyDetected();
        executingTransactions = true;

        // Allow caller to decide whether value is allowed to be attached to the transaction
        bool success;
        if (attachValue) {
            (success,) = transaction.target.call{value: transaction.value}(transaction.callData);
        } else {
            (success,) = transaction.target.call(transaction.callData);
        }

        // Ensure the transaction succeeded
        if (!success) revert FailedToExecuteTransaction();

        // Unlock the method for future execution of transactions
        executingTransactions = false;
    }
}