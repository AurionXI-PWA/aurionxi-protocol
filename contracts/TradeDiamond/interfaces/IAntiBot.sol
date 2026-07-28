// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/* ==============================================================
   IAntiBot.sol — Interface for AntiBotFacet (AurionXI)
   --------------------------------------------------------------
   ✅ Defines external functions exposed by AntiBotFacet
   ✅ Keeps diamond pattern modular and audit‑friendly
   ============================================================== */

interface IAntiBot {
	
		// ------------------ Events ------------------
    event AntiBotStatusChanged(bool enabled);
    event WalletFlagged(address indexed wallet, uint256 until);
    event TradeActivityDetected(address indexed wallet, uint256 tradeCount, uint256 timestamp);
    event DetectionParamsUpdated(uint256 windowSeconds, 
					uint256 maxTrades, uint256 restrictionHours);

    // @notice Called by ARXITokenFacet during transfers to monitor trading activity
    
	function monitorTrade(address trader) external;

    // @notice Enable or disable anti‑bot protection
    
	function setAntiBotActive(bool active) external;

    // @notice Update antibot detection parameters
    // @param windowSeconds Detection window in seconds
    // @param maxTrades Maximum trades allowed in window
    // @param restrictionHours Restriction duration in hours

    function setDetectionParams(
        uint256 windowSeconds,
        uint256 maxTrades,
        uint256 restrictionHours
    ) external;

    // @notice Check if a wallet is currently restricted
    
	function isRestricted(address wallet) external view returns (bool);

    // @notice Get current antibot configuration
    // @return enabled Whether antibot is active
    // @return tradeWindow Detection window in seconds
    // @return maxTradesPerWindow Maximum trades allowed in window
    // @return restrictionDuration Restriction duration in seconds
    
	function getAntiBotSettings()
        external
        view
        returns (
            bool enabled,
            uint256 tradeWindow,
            uint256 maxTradesPerWindow,
            uint256 restrictionDuration
        );
	

}
	
		
