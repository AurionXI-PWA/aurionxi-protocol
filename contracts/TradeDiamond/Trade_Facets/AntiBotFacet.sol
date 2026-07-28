// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../interfaces/IAntiBot.sol";

/*
|--------------------------------------------------------------------------
| ANTI-BOT SYSTEM
|--------------------------------------------------------------------------
| The Anti-Bot system helps detect and mitigate abusive automated
| trading behavior during token launch and throughout the protocol's
| lifecycle.
|
| Examples include:
|
| - High-frequency automated trading.
| - Sniping bots.
| - Transaction spam.
| - Manipulative trading patterns.
|
| The objective is to provide a fair trading environment for
| legitimate participants.
|--------------------------------------------------------------------------
*/

contract AntiBotFacet is IAntiBot {
	
		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
		}

    // =============================================================
    //                   OWNER CONTROL FUNCTIONS
    // =============================================================

    function setAntiBotActive(bool active) external onlyOwner{
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        s.antiBotActive = active;
        emit AntiBotStatusChanged(active);
    }

    function setDetectionParams(
        uint256 windowSeconds,
        uint256 maxTrades,
        uint256 restrictionHours
    ) external onlyOwner{
	    require(windowSeconds >= 30 && maxTrades > 0, "Invalid parameters");

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        s.tradeWindow = windowSeconds;
        s.maxTradesPerWindow = maxTrades;
        s.restrictionDuration = restrictionHours * 1 hours;

        emit DetectionParamsUpdated(windowSeconds, maxTrades, restrictionHours);
    }

    // =============================================================
	//                   MONITORING CORE LOGIC
	// =============================================================

	function monitorTrade(address trader) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		// ---------------------------------------------------------
		// AUTHORIZATION
		// Allow:
		// 1. Internal diamond self-calls (address(this))
		// 2. CoreDiamond owner/admin
		// ---------------------------------------------------------
		
		require(
			msg.sender == address(this) ||
			msg.sender == LibDiamond.contractOwner(),
			"NOT_AUTHORIZED"
		);

		// ---------------------------------------------------------
		// ANTIBOT STATUS
		// ---------------------------------------------------------
		if (!s.antiBotActive) return;
		
		// ---------------------------------------------------------
		// TEMP RESTRICTION CHECK
		// ---------------------------------------------------------
		if (block.timestamp < s.restrictedUntil[trader]) {
			revert("Wallet temporarily restricted (24h)");
		}

		// ---------------------------------------------------------
		// TRADE WINDOW TRACKING
		// ---------------------------------------------------------
		uint256 lastTrade = s.lastTradeTime[trader];

		if (block.timestamp - lastTrade <= s.tradeWindow) {
			s.tradeCount[trader] += 1;
		} else {
			s.tradeCount[trader] = 1;
		}

		s.lastTradeTime[trader] = block.timestamp;

		emit TradeActivityDetected(
			trader,
			s.tradeCount[trader],
			block.timestamp
		);

		// ---------------------------------------------------------
		// AUTO RESTRICTION
		// ---------------------------------------------------------
		if (s.tradeCount[trader] > s.maxTradesPerWindow) {
			s.restrictedUntil[trader] =
				block.timestamp +
				s.restrictionDuration;

			emit WalletFlagged(
				trader,
				s.restrictedUntil[trader]
			);
		}
	}

    // =============================================================
    //                     PUBLIC VIEW HELPERS
    // =============================================================

    function isRestricted(address wallet) external view returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return block.timestamp < s.restrictedUntil[wallet];
    }

    function getAntiBotSettings() external view returns (
            bool enabled,
            uint256 tradeWindow,
            uint256 maxTradesPerWindow,
            uint256 restrictionDuration
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.antiBotActive, s.tradeWindow, s.maxTradesPerWindow, s.restrictionDuration);
    }

	function getWalletTradeInfo(address wallet)
			external view returns (
				uint256 lastTradeTime,
				uint256 tradeCount,
				uint256 restrictedUntil,
				bool currentlyRestricted
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();
			lastTradeTime = s.lastTradeTime[wallet];
			tradeCount = s.tradeCount[wallet];
			restrictedUntil = s.restrictedUntil[wallet];
			currentlyRestricted = block.timestamp <
				s.restrictedUntil[wallet];
		}

}
 