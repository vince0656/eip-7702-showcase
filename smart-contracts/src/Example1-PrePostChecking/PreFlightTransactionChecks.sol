// SPDX-License-Identifier: MIT 
pragma solidity 0.8.28;

import {IERC20} from "../IERC20.sol";

contract PreFlightTransactionChecks {

    IERC20 public watchToken;

    constructor(IERC20 watchToken_) {
        watchToken = watchToken_;
    }

    /// @notice The following implementation of `runChecks()` is overly simplified that only protects a user against using EIP7702 AA on mainnet
    /// @dev Further and different checks could be implemented such as asset ownership, balance of assets, oracle results etc 
    /// @return uint256 The balance the wallet had of the watched token at the time of the pre-flight checks
    function runChecks(address wallet) external view returns (uint256) {
        require(block.chainid != 1, "Only testnet");
        return watchToken.balanceOf(wallet);
    }

}