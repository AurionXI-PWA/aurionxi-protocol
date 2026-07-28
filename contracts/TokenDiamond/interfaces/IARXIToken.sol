// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/* ==============================================================
   IARXIToken.sol — Interface for ARXITokenFacet
   --------------------------------------------------------------
   ✅ Defines ERC20 + Custom functions for AurionXI Token Facet
   ✅ Declares all relevant events for external listeners
   ✅ Contains only signatures (no logic)
   ============================================================== */

interface IARXIToken {
    // =============================================================
    //                          EVENTS
    // =============================================================
    event Paused(address indexed by, uint256 timestamp);
	event Unpaused(address indexed by, uint256 timestamp);

	event TokensBurned(address indexed from, uint256 amount, uint256 newTotalSupply);
	event TokensMinted(address indexed to, uint256 amount, uint256 newTotalSupply);
	event MinterUpdated(address indexed minter, bool enabled);
	
	event LPPairUpdated(address indexed pair, bool enabled);
	event MarketPairUpdated(address indexed account, bool value);
	
	event BlacklistUpdated(address indexed account, bool status);
	event BlacklistEnabledUpdated(bool enabled);
	
	event ListingTimestampSet(uint256 timestamp);
    
	// =============================================================
    // CONTROL & STATUS
    // =============================================================
	function enableEmergencyMode() external;
	function disableEmergencyMode() external;
	function isEmergencyMod() external view returns (bool);
	
	function pause() external;
    function unpause() external;
	function isPaused() external view returns (bool);
	
	// =============================================================
    // MINT / BURN
    // =============================================================
    function burn(uint256 amount) external;
    function mint(address to, uint256 amount) external;
    function setAuthorizedMinter(address minter, bool enabled) external;
	function isAuthorizedMinter(address minter) external view returns (bool);
	
	// ===========================================================
	//     LIQUIDITY + MARKET PAIR
	// ===========================================================
	function setLPPair(address pair, bool enabled) external;
	function setMarketPair(address account, bool value) external;
	function registerPair(address pair) external;
	
	//============================================================
	//============== BlacklistEnabledUpdated =====================
	//============================================================
	function setBlacklist(address account, bool status) external;
	function setBlacklistEnabled(bool enabled) external;
	
	// ======================================================
	// Listing timestamp setup
	// ======================================================
	function setListingTimestamp(uint256 ts) external;
	 
	}
	