// SPDX-License-Identifier: MIT 
pragma solidity 0.8.28;

import {IERC20} from "../IERC20.sol";

contract PostTransactionAccountState {

    /// @notice Whilst this function requires work to be generalized it shows how account state can be checked at the end of a transaction
    function runAccountStateChecks(address wallet, IERC20 watchToken, uint256 balanceBefore) external view {
        // In this implementation we'd like to ensure the balance of a token was not touched
        require(watchToken.balanceOf(wallet) == balanceBefore, "The balance of the watch token changed");
    }

}