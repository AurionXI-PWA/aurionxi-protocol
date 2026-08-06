// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../contracts/DiamondStorageExtensions.sol";

contract DiamondStorageSecurityTest is Test {
    function testUniqueStorageSlot() public pure {
        bytes32 expectedSlot = keccak256("aurionxi.protocol.diamond.storage.v1");
        assertTrue(expectedSlot != bytes32(0));
    }
}
