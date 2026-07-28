// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../libraries/LibCoreStorage.sol";
import { ICoreDiamondCut } from "./../CoreDiamond/interfaces/ICoreDiamondCut.sol";
 
contract TradeDiamond {
	
	event CoreDiamondTradeBound(address coreDiamond);
	event ChildTradeOwnerBound(address indexed child, address indexed owner);

	constructor(address coreDiamond, address coreDiamondCutFacet) payable 
	{
		require(coreDiamond != address(0), "CoreDiamond required here");
		require(coreDiamondCutFacet != address(0), "CoreDiamondCutFacet required here");

		// Set CoreDiamond as the owner
		LibDiamond.setContractOwner(coreDiamond);
			
	// Store CoreDiamond reference in CoreStorage
   
    LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
    cs.coreDiamond = coreDiamond;
    require(cs.coreDiamond != address(0), "CoreDiamond address not set");
	
	emit CoreDiamondTradeBound(coreDiamond);
	emit ChildTradeOwnerBound(address(this), coreDiamond);

		
		
		// Bootstrap diamondCut for TradeDiamond
		bytes4[] memory selectors = new bytes4[](1);
		selectors[0] = ICoreDiamondCut.diamondCut.selector;

		ICoreDiamondCut.FacetCut[] memory cut = new ICoreDiamondCut.FacetCut[](1);
		cut[0] = ICoreDiamondCut.FacetCut
		({
			facetAddress: coreDiamondCutFacet,
			action: ICoreDiamondCut.FacetCutAction.Add,
			functionSelectors: selectors
		});

		LibDiamond.diamondCut(_convertCut(cut), address(0), "");
	}

    /*//////////////////////////////////////////////////////////////
                            FALLBACK
    //////////////////////////////////////////////////////////////*/

    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		// Verify CoreDiamond reference from CoreStorage
		require(cs.coreDiamond != address(0), "CoreDiamond address not set");
		
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "TradeDiamond: Function not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
        }
    }

    receive() external payable {
        revert("TRADE_DIAMOND_NO_ETH");
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL HELPERS
    //////////////////////////////////////////////////////////////*/

    function _convertCut(ICoreDiamondCut.FacetCut[] memory _cut)
        internal pure returns (LibDiamond.FacetCut[] memory converted)
    {
        converted = new LibDiamond.FacetCut[](_cut.length);
        for (uint256 i = 0; i < _cut.length; i++) {
            converted[i] = LibDiamond.FacetCut({
                facetAddress: _cut[i].facetAddress,
                action: LibDiamond.FacetCutAction(uint8(_cut[i].action)),
                functionSelectors: _cut[i].functionSelectors
            });
        }
    }
}
