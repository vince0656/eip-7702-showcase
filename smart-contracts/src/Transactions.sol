// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @dev Reusable logic for executing any EVM transaction with built in re-entrancy and control over msg.value
/// @author Vincent Almeida
abstract contract Transactions {

    /// @dev Error messages
    error FailedToExecuteTransaction();
    error NoTransactions();
    error ReentrancyDetected();
    error MsgValueNotZero();

    /// @dev Data structure for an arbitrary transaction
    struct Transaction {
        address target; // Address of the smart contract that will be executed
        uint256 value;  // Any msg.value that needs to be sent to the target
        bytes callData; // The raw encoded function call and data
    }

    /// @dev Use a transient storage variable for reentrancy protection
    bool private transient executingTransactions;

    /// @dev Reusable logic for executing any EVM transaction with built in re-entrancy
    function executeTransaction(Transaction memory transaction, bool attachValue) internal {
        // Ensure we have reentrancy protection
        require(!executingTransactions, ReentrancyDetected());
        executingTransactions = true;

        // Allow caller to decide whether value is allowed to be attached to the transaction
        bool success;
        if (attachValue) {
            (success,) = transaction.target.call{value: transaction.value}(transaction.callData);
        } else {
            // Ensure there is no value attached to the transaction otherwise it will just sit in the contract
            require(msg.value == 0, MsgValueNotZero());

            // Call the target contract but do not attach any value
            (success,) = transaction.target.call(transaction.callData);
        }

        // Ensure the transaction succeeded
        require(success, FailedToExecuteTransaction());

        // Unlock the method for future execution of transactions
        executingTransactions = false;
    }
}