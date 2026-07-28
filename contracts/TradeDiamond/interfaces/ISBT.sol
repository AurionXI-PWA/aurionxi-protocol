// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ISBT {
    function balanceOf(address owner) external view returns (uint256);
}