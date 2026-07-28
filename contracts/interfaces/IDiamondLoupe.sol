// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IDiamondLoupe
 * @notice EIP-2535 Diamond Loupe interface
 */
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their selectors
    function facets() external view returns (Facet[] memory);

    /// @notice Gets all selectors for a facet
    function facetFunctionSelectors(address _facet)
									external view returns (bytes4[] memory);

    /// @notice Gets all facet addresses
    function facetAddresses() external view returns (address[] memory);

    /// @notice Gets the facet that supports a selector
    function facetAddress(bytes4 _selector) external view returns (address);
}
