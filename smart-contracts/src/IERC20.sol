// SPDX-License-Identifier: MIT 
pragma solidity 0.8.28;

/// @dev Minimal IERC20 interface
interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address,address,uint256) external returns (bool);
    function transfer(address,uint256) external returns (bool);
}