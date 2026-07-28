// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract CoreEmergencyReadFacet {
    function emergencyReadFacetName()
        external
        pure
        returns (string memory)
    {
        return "CoreEmergencyReadFacet";
    }

    function emergencyReadFacetVersion()
        external
        pure
        returns (uint256)
    {
        return 1;
    }

    function emergencyReadFacetPing()
        external
        pure
        returns (bool)
    {
        return true;
    }

    function getEmergencyReadInfo()
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