// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { IAnalyticDiamondLoupe } from "../interfaces/IAnalyticDiamondLoupe.sol";

contract AnalyticDiamondLoupeFacet is IAnalyticDiamondLoupe {
    function facets() external view override returns (Facet[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        Facet[] memory result = new Facet[](numFacets);

        for (uint256 i = 0; i < numFacets; i++) {
            address facetAddr = ds.facetAddresses[i];
            result[i].facetAddress = facetAddr;
            result[i].functionSelectors =
                ds.facetFunctionSelectors[facetAddr].functionSelectors;
        }

        return result;
    }

    function facetFunctionSelectors(address facet)
        external
        view
        override
        returns (bytes4[] memory)
    {
        return LibDiamond
            .diamondStorage()
            .facetFunctionSelectors[facet]
            .functionSelectors;
    }

    function facetAddresses()
        external
        view
        override
        returns (address[] memory)
    {
        return LibDiamond.diamondStorage().facetAddresses;
    }

    function facetAddress(bytes4 selector)
        external
        view
        override
        returns (address)
    {
        return LibDiamond
            .diamondStorage()
            .selectorToFacetAndPosition[selector]
            .facetAddress;
    }
}