// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/* ==============================================================
   IARXITokenInitFacet.sol — Interface for ARXITokenFacet
   --------------------------------------------------------------
   ✅ Defines ERC20 + Custom functions for INITIALIZATION AurionXI Token Facet
   ✅ Declares all relevant events for external listeners
   ✅ Contains only signatures (no logic)
   ============================================================== */

interface IARXITokenInit  {
	
    event InitializedToken(string name, string symbol, uint256 totalSupply);
	event MaxSupplyToken(uint256 maxSupply);
	event InitializationLocked(address indexed owner);
	
		// ============================================
		// INITIALIZATION
		// ============================================
	function initializeToken(
		string memory name_,
		string memory symbol_,
		uint256 totalSupply_,
		uint256 initialBuyTaxBps,
		uint256 initialSellTaxBps,
		address initialSupplyRecipient
		) external;		
		
					
	function initializeWallets(
		address initialFeeCollector,
		address _treasuryWallet,
		address _rewardDistributor,
		address _liquidityLocker,
		address _marketingWallet,
		address _burnWallet
			) external;		
			
		// =====================================================
		// TOKEN INITIALIZATION
		// =====================================================
		
		function tokenMaxSupply(uint256 _maxSupply) external;
		function lockInitialization() external;

	}