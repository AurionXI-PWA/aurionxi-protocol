// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

	interface ICoreDiamondCut {
	
		// @notice Emitted when the diamond is upgraded
			
	//=============== FACET EVENTS ================================
	event DiamondUpgradeExecuted(bytes32 indexed upgradeHash, address indexed executor);
	event FacetAdded(address indexed facet, bytes4[] selectors);
	event FacetRemoved(address indexed facet, bytes4[] selectors);
	event FacetReplaced(address indexed oldFacet, address indexed newFacet, bytes4[] selectors);
	event FacetSelectorRemoved(address indexed oldFacet, bytes4 indexed selector);

		enum FacetCutAction {
			Add,
			Replace,
			Remove
		}
		
		enum Mode {
			BOOTSTRAP,
			EMERGENCY,
			PRODUCTION
		}


		struct FacetCut {
			address facetAddress;
			FacetCutAction action;
			bytes4[] functionSelectors;
		}

		// @notice Add/replace/remove functions
		// @param _cut Facet changes
		// @param _init Initialization contract
		// @param _calldata Initialization call data
		
		function diamondCut(
			FacetCut[] calldata _cut,
			address _init,
			bytes calldata _calldata
		) external;

	}