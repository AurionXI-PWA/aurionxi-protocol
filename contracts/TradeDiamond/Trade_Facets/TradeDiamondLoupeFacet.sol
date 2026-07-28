// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { ITradeDiamondLoupe } from "../interfaces/ITradeDiamondLoupe.sol";

contract TradeDiamondLoupeFacet is ITradeDiamondLoupe {
    
	function facets() external view override returns (Facet[] memory) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        Facet[] memory result = new Facet[](numFacets);

        for (uint256 i = 0; i < numFacets; i++) {
            address facetAddr = ds.facetAddresses[i];
            bytes4[] memory selectors = ds.facetFunctionSelectors[facetAddr].functionSelectors;
            result[i].facetAddress = facetAddr;
            result[i].functionSelectors = selectors;
        }
        return result;
    }

    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory)
    {
        return LibDiamond.diamondStorage().facetFunctionSelectors[_facet].functionSelectors;
    }

    function facetAddresses() external view override returns (address[] memory) {
        return LibDiamond.diamondStorage().facetAddresses;
    }

    function facetAddress(bytes4 _selector) external view override returns (address) {
        return LibDiamond.diamondStorage().selectorToFacetAndPosition[_selector].facetAddress;
    }
}
