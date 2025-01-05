// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Transactions} from "@contracts/Transactions.sol";
import {IWETH} from "./IWETH.sol";

/// @notice An EOA EIP7702 wallet upgrade that allows an EOA to execute transactions using ETH of a nominated treasury and returning back change like a UTXO transaction
/// @dev The aim is to assist with operational security where an organisation may have their ETH located in a single treasury but wants to fund on-chain actions for one transaction only from other accounts
contract NoETHAccount is Transactions {

    /// @dev Error messages
    error ZeroAddress();
    error ZeroBudget();
    error FailedToCall();

    /// @notice Account holding the ETH required for GAS and account that will receive change
    address public treasury;

    /// @notice Address of the wrapped ETH smart contract to facilitate pulling ETH into the smart EOA
    IWETH public wETH;

    /// @notice Arbitrary max amount that will be pulled from the treasury and assumes transaction will execute within the budget
    uint256 public maxWETHPerTransaction;

    /// @notice Whether an authorisation to use this code with EIP7702 would allow ETH balance to be spent by the transaction OPs
    bool public allowTransactionsWithValue;

    /// @param treasury_ The address of the account that will fund the transactions and receive the change back after executing transactions
    /// @param wETH_ The wrapped ETH smart contract that will be used to pull ETH into the smart EOA
    /// @param maxWETHPerTransaction_ The maximum amount of ETH that will be pulled from the treasury each time a batch of transactions is executed
    /// @param allowTransactionsWithValue_ Whether an authorisation to use this code with EIP7702 would allow ETH balance to be spent by the transaction OPs
    constructor(address treasury_, IWETH wETH_, uint256 maxWETHPerTransaction_, bool allowTransactionsWithValue_) {
        require(treasury_ != address(0), ZeroAddress());
        require(address(wETH_) != address(0), ZeroAddress());
        require(maxWETHPerTransaction_ != 0, ZeroBudget());
        treasury = treasury_;
        wETH = wETH_;
        maxWETHPerTransaction = maxWETHPerTransaction_;
        allowTransactionsWithValue = allowTransactionsWithValue_;
    }

    /// @notice Use an EOA for a specific batch of transactions where a treasury funds a transaction and the EOA refunds the treasury of any change making operational management of EOAs more straightforward
    /// @param transactions The transactions to execute
    function executeOpsWithNoETH(Transaction[] calldata transactions) external payable {
        // Bring in funds from the treasury and unwrap wETH so the EOA gets GAS
        wETH.transferFrom(treasury, address(this), maxWETHPerTransaction);
        wETH.withdraw(maxWETHPerTransaction);

        // Execute the transactions (could be a deployment for example where a treasury trustlessly pays for the deployment GAS)
        for (uint256 i; i < transactions.length; ++i) {
            executeTransaction(transactions[i], allowTransactionsWithValue);
        }

        // Return any unused funds such that the EOA at the end of the transaction remains with NO ETH in its possession allowing the EOA to be thrown away 
        wETH.deposit{value: address(this).balance}();
        wETH.transfer(treasury, wETH.balanceOf(address(this)));
    }

    /// @notice Allow the smart contract to receive ETH but do not implement any functionality to ensure 21,000 gas limit is respected
    receive() external payable {}

}