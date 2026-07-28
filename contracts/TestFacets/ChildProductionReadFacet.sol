// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract ChildProductionReadFacet {
    function childProductionReadFacetName()
        external
        pure
        returns (string memory)
    {
        return "ChildProductionReadFacet";
    }

    function childProductionReadFacetVersion()
        external
        pure
        returns (uint256)
    {
        return 1;
    }

    function childProductionReadFacetPing()
        external
        pure
        returns (bool)
    {
        return true;
    }

    function getChildProductionReadInfo()
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