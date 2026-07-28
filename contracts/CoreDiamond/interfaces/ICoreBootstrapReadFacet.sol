// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ICoreBootstrapReadFacet {
    function bootstrapReadFacetName() external pure returns (string memory);
    function bootstrapReadFacetVersion() external pure returns (uint256);
    function bootstrapReadFacetPing() external pure returns (bool);

    function getBootstrapReadInfo()
        external
        view
        returns (
            address diamondAddress,
            uint256 chainId,
            uint256 blockNumber,
            uint256 blockTimestamp
        );
}