// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

abstract contract Transactions {
    error FailedToExecuteTransaction();

    struct Transaction {
        address target; // Address of the smart contract that will be executed
        uint256 value;  // Any msg.value that needs to be sent to the target
        bytes callData; // The raw encoded function call and data
    }

    /// @dev Use a transient storage variable for reentrancy protection
    bool transient executingTransactions;

    /// @dev Reusable logic for executing any EVM transaction
    function executeTransaction(Transaction memory transaction) internal {
        (bool success,) = transaction.target.call{value: transaction.value}(transaction.callData);
        if (!success) revert FailedToExecuteTransaction();
    }
}