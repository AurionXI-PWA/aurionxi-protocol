// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract CoreBootstrapReadFacet {
    function bootstrapReadFacetName()
        external
        pure
        returns (string memory)
    {
        return "CoreBootstrapReadFacet";
    }

    function bootstrapReadFacetVersion()
        external
        pure
        returns (uint256)
    {
        return 1;
    }

    function bootstrapReadFacetPing()
        external
        pure
        returns (bool)
    {
        return true;
    }

    function getBootstrapReadInfo()
        external
        view
        returns (
            address diamondAddress,
            uint256 chainId,
            uint256 blockNumber,
            uint256 blockTimestamp
        )
    {
        return (
            address(this),
            block.chainid,
            block.number,
            block.timestamp
        );
    }
}