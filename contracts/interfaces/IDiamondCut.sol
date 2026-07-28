// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// @title DiamondCut Interface
// @notice Standard for adding/replacing/removing facets

interface IDiamondCut {
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    // @notice Add/replace/remove facet functions
    // @param _diamondCut Facet changes
    // @param _init Address of initialization function
    // @param _calldata Data for initialization function
    
	function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}