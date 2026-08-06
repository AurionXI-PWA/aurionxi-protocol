// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library DiamondStorageExtensions {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("aurionxi.protocol.diamond.storage.v1");

    struct DiamondStorage {
        mapping(bytes4 => address) selectorToFacet;
        mapping(address => bool) authorizedFacets;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
