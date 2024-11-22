// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "../IERC20.sol";
import {Transactions} from "../Transactions.sol";

import {PreFlightTransactionChecks} from "./PreFlightTransactionChecks.sol";
import {PostTransactionAccountState} from "./PostTransactionAccountState.sol";

/// @notice An EOA EIP7702 wallet upgrade that takes the Check Effects Interaction Pattern Further by adding checks at the end. Hence: 'Checks Effects Interaction Checks' Pattern
contract EIP7702SmartContractWallet is Transactions {

    error NoTransactions();
    error ReentrancyDetected();

    /// @notice Address of the smart contract that does pre-flight transaction checks
    PreFlightTransactionChecks public preFlightChecks;

    /// @notice Address of the smart contract that will check a user's account state post executing transactions
    PostTransactionAccountState public postTransaction;

    /// @param watchToken The token that is watched as part of the pre and post transaction checks
    constructor(IERC20 watchToken) {
        preFlightChecks = new PreFlightTransactionChecks(watchToken);
        postTransaction = new PostTransactionAccountState();
    }

    /// @notice Execute an arbitrary number of transactions ensuring the account is checked before and after the transactions are executed
    function executeBatchTransactions(Transaction[] calldata transactions) public payable {
        if (transactions.length == 0) revert NoTransactions();

        // Ensure we have reentrancy protection
        if (executingTransactions) revert ReentrancyDetected();
        executingTransactions = true;

        // Run pre-transaction checks (The initial 'Checks' from the 'Checks Effects Interaction Checks' Pattern)
        uint256 watchTokenBalanceBefore = preFlightChecks.runChecks(address(this));

        // Execute arbitrary logic (The 'Effects Interaction' from the 'Check Effects Interaction Checks' Pattern)
        for (uint256 i; i < transactions.length; ++i) {
            Transaction memory transaction = transactions[i];
            executeTransaction(transaction);
        }

        // Ensure the post account state is acceptable (The final 'Checks' from the 'Checks Effects Interaction Checks' Pattern)
        postTransaction.runAccountStateChecks(address(this), preFlightChecks.watchToken(), watchTokenBalanceBefore);

        // Unlock the method for future execution of transactions
        executingTransactions = false;
    }

}