// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Transactions} from "../Transactions.sol";
import {IWETH} from "./IWETH.sol";

/// @notice An EOA EIP7702 wallet upgrade that allows an EOA to execute transactions using ETH of a nominated treasury and returning back change like a UTXO transaction
/// @dev The aim is to assist with operational security where an organisation may have their ETH located in a single treasury but wants to fund on-chain actions for one transaction only from other accounts
contract NoETHAccount is Transactions {

    error ZeroAddress();
    error ZeroBudget();
    error FailedToCall();
    
    /// @notice Account holding the ETH required for GAS and account that will receive change
    address public treasury;

    /// @notice Address of the wrapped ETH smart contract to facilitate pulling ETH into the smart EOA
    IWETH public wETH;

    /// @notice Arbitrary max amount that will be pulled from the treasury and assumes transaction will execute within the budget
    uint256 public maxWETHPerTransaction;

    constructor(address treasury_, IWETH wETH_, uint256 maxWETHPerTransaction_) {
        if (treasury_ == address(0)) revert ZeroAddress();
        if (address(wETH_) == address(0)) revert ZeroAddress();
        if (maxWETHPerTransaction_ == 0) revert ZeroBudget();
        treasury = treasury_;
        wETH = wETH_;
        maxWETHPerTransaction = maxWETHPerTransaction_;
    }

    /// @notice Use an EOA for a specific batch of transactions where a treasury funds a transaction and the EOA refunds the treasury of any change making operational management of EOAs more straightforward
    function executeOpsWithNoETH(Transaction[] calldata transactions) external payable {
        // Bring in funds from the treasury and unwrap wETH so the EOA gets GAS
        wETH.transferFrom(treasury, address(this), maxWETHPerTransaction);
        wETH.withdraw(maxWETHPerTransaction);

        // Execute the transactions (could be a deployment for example where a treasury trustlessly pays for the deployment GAS)
        for (uint256 i; i < transactions.length; ++i) {
            Transaction memory transaction = transactions[i];
            executeTransaction(transaction);
        }

        // Return any unused funds such that the EOA at the end of the transaction remains with NO ETH in its possession allowing the EOA to be thrown away 
        wETH.deposit{value: address(this).balance}();
        wETH.transfer(treasury, wETH.balanceOf(address(this)));
    }

}