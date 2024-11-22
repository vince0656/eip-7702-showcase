// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "../IERC20.sol";

/// @dev Minimal WETH9 interface
interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
}