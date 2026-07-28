// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

contract CoreProductionReadFacet {
    function productionReadFacetName() external pure returns (string memory) {
        return "CoreProductionReadFacet";
    }

    function productionReadFacetVersion() external pure returns (uint256) {
        return 1;
    }

    function productionReadFacetPing() external pure returns (bool) {
        return true;
    }

    function getProductionReadInfo()
        external
        view
        returns (
            address diamondAddress,
            uint256 chainId,
            uint256 blockNumber,
            uint256 blockTimestamp
        )
    {
        return (address(this), block.chainid, block.number, block.timestamp);
    }
}