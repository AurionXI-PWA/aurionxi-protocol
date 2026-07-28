// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ITradeReadFacet {
		function isAntiBotActive()
			external
			view
			returns (bool);

		function getAntiBotParams()
			external
			view
			returns (
				uint256 tradeWindow,
				uint256 maxTradesPerWindow,
				uint256 restrictionDuration
			);

		function isWalletLocked()
			external
			view
			returns (bool);

		function getRetailLimits()
			external
			view
			returns (
				uint256 walletBps,
				uint256 sellBps,
				uint256 cooldown
			);

		function getSellStatus()
			external
			view
			returns (
				bool retailEnabled,
				bool institutionEnabled
			);

		function isInstitution(address user)
			external
			view
			returns (bool);

		function getSellProtection()
			external
			view
			returns (
				bool microSellEnabled,
				bool panicSellEnabled
			);
			
		function getMicroSellConfig() 
			external 
			view 
			returns (
				uint256 minLowSell,
				uint256 minHighSell,
				uint256 microSellTaxBps
			);
		
		function getPanicSellTax()
			external
			view
			returns (
				uint256 softTax,
				uint256 mediumTax,
				uint256 hardTax,
				uint256 microTax
			);		
		
		function getMicroSellConfiguration()
			external
			view
			returns (
				bool enabled,
				uint256 minLowSell,
				uint256 minHighSell,
				uint256 microSellTaxBps
			);
		
		function getPanicSellConfig()
			external
			view
			returns (
				bool enabled,
				uint256 softThresholdBps,
				uint256 mediumThresholdBps,
				uint256 hardThresholdBps,
				uint256 softTaxBps,
				uint256 mediumTaxBps,
				uint256 hardTaxBps
			);
			
		function getTaxConfig()
			external
			view
			returns (
				uint256 currentBuyTax,
				uint256 currentSellTax,
				uint256 buyTaxCap,
				uint256 sellTaxCap
			);

		function getCooldownRemaining(address user)
			external
			view
			returns (uint256);

		function getMaxRetailBuyAmount(address user)
			external
			view
			returns (uint256);

		function getMaxRetailSellAmount(address user)
			external
			view
			returns (uint256);

		function canBuy(address user, uint256 amount)
			external
			view
			returns (
				bool ok,
				string memory reason
			);

		function canSell(address user, uint256 amount)
			external
			view
			returns (
				bool ok,
				string memory reason
			);

		function getUserTradeVolumes(address user)
			external
			view
			returns (
				uint256 totalTrade,
				uint256 totalBuy,
				uint256 totalSell
			);

		 
	}