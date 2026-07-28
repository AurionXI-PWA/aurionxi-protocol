// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (EIP-2535 reference)
* Modified: AurionXI — architecture-safe, no behavior changes
\******************************************************************************/
/*
|--------------------------------------------------------------------------
| DIAMOND GOVERNANCE
|--------------------------------------------------------------------------
| LibDiamond manages ownership, facet upgrades and protocol administration.
|
| Administrative permissions exist solely for protocol maintenance,
| security updates and emergency response.
|
| All upgrades should preserve storage compatibility and protocol integrity.
|--------------------------------------------------------------------------
*/

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

		struct FacetAddressAndPosition {
			address facetAddress;
			uint96 functionSelectorPosition;
		}

		struct FacetFunctionSelectors {
			bytes4[] functionSelectors;
			uint256 facetAddressPosition;
		}

		struct DiamondStorage {
			// selector => facet address and selector position
			mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
			
			// facet address => selectors
			mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
			
			// facet addresses
			address[] facetAddresses;
			
			// supported interfaces
			mapping(bytes4 => bool) supportedInterfaces;
			
			// contract owner
			address contractOwner;
		}

event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

		/*//////////////////////////////////////////////////////////////
								OWNERSHIP
		//////////////////////////////////////////////////////////////*/

		function setContractOwner(address _newOwner) internal {
			DiamondStorage storage ds = diamondStorage();
			address previousOwner = ds.contractOwner;
			ds.contractOwner = _newOwner;
			emit OwnershipTransferred(previousOwner, _newOwner);
		}

		function contractOwner() internal view returns (address) {
			return diamondStorage().contractOwner;
		}

		function enforceIsContractOwner() internal view {
			require(
				msg.sender == diamondStorage().contractOwner,
				"LibDiamond: Must be contract owner"
			);
		}

    /*//////////////////////////////////////////////////////////////
                            DIAMOND CUT
    //////////////////////////////////////////////////////////////*/

    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }
 
 event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondCut(
        FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }	

        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /*//////////////////////////////////////////////////////////////
                        ADD / REPLACE / REMOVE
    //////////////////////////////////////////////////////////////*/

	// HERE ADD MORE FUNCTIONS AT A TIME
    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: There are No selectors here");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), 
			"LibDiamondCut: Adding FUNCTIONS Address is zero");

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );

        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }

    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
        bytes4 selector = _functionSelectors[selectorIndex];
        address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
        
		require(oldFacetAddress == address(0), 
		"LibDiamondCut: Adding FunctionS Exists and if Old address, should be 0 address");

        addFunction(ds, selector, selectorPosition, _facetAddress);
        selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, 
		"LibDiamondCut: There ARE No selectors Find to Replace FUNCTIONS SELECTORS");
        
		DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), 
		"LibDiamondCut: There ARE Replace facetS zero addressESS");

        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );

        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector]
                .facetAddress;
            require(oldFacetAddress != _facetAddress, 
					"LibDiamondCut: Same FACETS Address");
            
			removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors FOR Remove");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress == address(0), 
			"LibDiamondCut: Remove facetS must be zero");

        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(
        DiamondStorage storage ds,
        address _facetAddress
    ) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: IN addFacet No code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition =
            ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }
	
	function removeFacet(DiamondStorage storage ds, address _facetAddress) internal {
		require(_facetAddress != address(0), "LibDiamondCut: removeFacet zero address");

		// Clear selectors mapping
		delete ds.facetFunctionSelectors[_facetAddress];

		// Swap-and-pop from facetAddresses
		uint256 length = ds.facetAddresses.length;
		for (uint256 i = 0; i < length; i++) {
			if (ds.facetAddresses[i] == _facetAddress) {
				ds.facetAddresses[i] = ds.facetAddresses[length - 1];
				ds.facetAddresses.pop();
				break;
			}
		}
	}
	
	function replaceFacet(
		DiamondStorage storage ds,
		address _oldFacet,
		address _newFacet
	) internal {
		require(_newFacet != address(0), "LibDiamondCut: replaceFacet zero address");
		enforceHasContractCode(_newFacet, "LibDiamondCut: replaceFacet no code");

		// First remove old facet
		removeFacet(ds, _oldFacet);

		// Then add new facet
		addFacet(ds, _newFacet);
	}

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition =
            _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }
	
	function replaceFunction(
		DiamondStorage storage ds,
		address _facetAddress,
		bytes4 _selector
	) internal {
		// Find old facet
		address oldFacet = ds.selectorToFacetAndPosition[_selector].facetAddress;
		require(oldFacet != address(0), "LibDiamond: Function not exist");
		require(oldFacet != _facetAddress, 
				"LibDiamond: Cannot replace with same facet");

		// Remove from old facet
		removeFunction(ds, oldFacet, _selector);

		// Add to new facet
		uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
		addFunction(ds, _selector, selectorPosition, _facetAddress);
	}

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), 
				"LibDiamondCut: selector not found for removeFunction");

        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors.length - 1;

        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress]
                .functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }

        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        if (ds.facetFunctionSelectors[_facetAddress].functionSelectors.length == 0) {
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;

            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }

            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: calldata nonempty");
        } else {
            enforceHasContractCode(_init, "LibDiamondCut: init no code");
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: init failed");
                }
            }
        }
    }

		function enforceHasContractCode(address _contract, string memory _errorMessage
			) internal view {
				uint256 size;
				assembly {
					size := extcodesize(_contract)
				}
				require(size > 0, _errorMessage);
			}
		
		
		function facetAddress(bytes4 _selector)
			internal
			view
			returns (address)
		{
			DiamondStorage storage ds = diamondStorage();
			return ds.selectorToFacetAndPosition[_selector].facetAddress;
		}
		
		function removeSelector(bytes4 _selector) internal {

			DiamondStorage storage ds = diamondStorage();

			address oldFacet =
				ds.selectorToFacetAndPosition[_selector].facetAddress;

			require(oldFacet != address(0), "SELECTOR_NOT_FOUND");

			delete ds.selectorToFacetAndPosition[_selector];
		}
		
		function replaceSelector(
			bytes4 _selector,
			address _newFacet
		) internal {

			DiamondStorage storage ds = diamondStorage();

			require(_newFacet != address(0), "INVALID_FACET");

			require(
				ds.selectorToFacetAndPosition[_selector].facetAddress != address(0),
				"SELECTOR_NOT_FOUND"
			);

			ds.selectorToFacetAndPosition[_selector].facetAddress = _newFacet;
		}
		
		
		function diamondStorage() 
			internal 
			pure 
			returns (DiamondStorage storage ds)
		{
			bytes32 position = DIAMOND_STORAGE_POSITION;
			assembly {
				ds.slot := position
			}
		}

	}
