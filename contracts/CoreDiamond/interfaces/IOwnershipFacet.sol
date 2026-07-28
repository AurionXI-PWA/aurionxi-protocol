// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IOwnershipFacet {

    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
}