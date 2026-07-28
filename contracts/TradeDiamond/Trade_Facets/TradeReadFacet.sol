// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../interfaces/ISBT.sol";

contract TradeReadFacet 
	{
		
		function _isLimitExempt(address user) internal view returns (bool) {
		LibAppStorage.AppStorage storage s =
			LibAppStorage.diamondStorage();

		return (
			s.isExemptFromLimits[user] ||
			s.isExcludedFromLimits[user]
			);
		}
		
		// ============================================================
		// 🔹 ANTIBOT READ
		// ============================================================

		function isAntiBotActive() external view returns (bool) {
			return LibAppStorage.diamondStorage().antiBotActive;
		}

		function getAntiBotParams() external view returns (
				uint256 tradeWindow,
				uint256 maxTradesPerWindow,
				uint256 restrictionDuration
			)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return (
				s.tradeWindow,
				s.maxTradesPerWindow,
				s.restrictionDuration
			);
		}


		function isWalletLocked() external view returns (bool) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return s.walletsLocked;
		}

		// ============================================================
		// 🔹 INSTITUTION / RETAIL READ
		// ============================================================
		function getRetailLimits()
			external
			view
			returns (
				uint256 walletBps,
				uint256 sellBps,
				uint256 cooldown
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return (
				s.retailMaxWalletBps,
				s.retailSellMaxBps,
				s.retailSellCooldown
			);
		}

		function getSellStatus() external view
			returns (bool retailEnabled, bool institutionEnabled)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return (s.retailSellEnabled, s.institutionSellEnabled);
		}

		function isInstitution(address user) external view returns (bool) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return s.isInstitutionApproved[user];
		}
		
		
		// ============================================================
		// 🔹 TAX / PANIC READ
		// ============================================================

		function getSellProtection() external view
			returns (bool microSellEnabled, bool panicSellEnabled)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return (s.microSellEnabled, s.panicSellEnabled );
		}

		function getMicroSellConfig() 
			external 
			view 
			returns (
				uint256 minLowSell,
				uint256 minHighSell,
				uint256 microSellTaxBps
			)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			return (
				s.minLowSell,
				s.minHighSell,
				s.microSellTaxBps
			);
		}

		function getPanicSellTax()
			external
			view
			returns (
				uint256 softTax,
				uint256 mediumTax,
				uint256 hardTax,
				uint256 microTax
			)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			return (
				s.panicSoftTaxBps,
				s.panicMediumTaxBps,
				s.panicHardTaxBps,
				s.microSellTaxBps
			);
		}
		
		function getMicroSellConfiguration()
			external
			view
			returns (
				bool enabled,
				uint256 minLowSell,
				uint256 minHighSell,
				uint256 microSellTaxBps
			)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			return (
				s.microSellEnabled,
				s.minLowSell,
				s.minHighSell,
				s.microSellTaxBps
			);
		}

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
			)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			return (
				s.panicSellEnabled,
				s.panicSoftBps,
				s.panicMediumBps,
				s.panicHardBps,
				s.panicSoftTaxBps,
				s.panicMediumTaxBps,
				s.panicHardTaxBps
			);
		}

		function getTaxConfig()
			external
			view
			returns (
				uint256 currentBuyTax,
				uint256 currentSellTax,
				uint256 buyTaxCap,
				uint256 sellTaxCap
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return (
				s.buyTaxBps,
				s.sellTaxBps,
				s.maxBuyTaxBps,
				s.maxSellTaxBps
			);
		}
		
		function _hasSBT(address user) internal view returns (bool) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			if (!s.sbtCheckEnabled || s.sbtContract == address(0)) {
				return false;
			}

			try ISBT(s.sbtContract).balanceOf(user) returns (uint256 balance) {
				return balance > 0;
			} catch {
				return false;
			}
		}
		
		function _holdsSBT(address user) internal view returns (bool) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			if (s.sbtContract == address(0)) {
				return false;
			}

			try ISBT(s.sbtContract).balanceOf(user) returns (uint256 balance) {
				return balance > 0;
			} catch {
				return false;
			}
		}


		function getCooldownRemaining(address user) external view returns (uint256) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			uint256 cooldown;
			uint256 lastSell;

			if (s.isInstitutionApproved[user]) {
				cooldown = s.institutionSellCooldown[user] > 0
					? s.institutionSellCooldown[user]
					: s.institutionDefaultSellCooldown;
				lastSell = s.institutionLastSell[user];
			} else {
				cooldown = s.retailSellCooldown;
				lastSell = s.lastRetailSell[user];
			}

			if (cooldown == 0 || block.timestamp >= lastSell + cooldown) {
				return 0;
			}

			return (lastSell + cooldown) - block.timestamp;
		}

		function getMaxRetailBuyAmount(address user) external view returns (uint256) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			bool hasSBT = _hasSBT(user);
			uint256 maxWalletBps = hasSBT
				? s.retailSbtMaxWalletBps
				: s.retailMaxWalletBps;

			if (maxWalletBps == 0) {
				return type(uint256).max;
			}

			uint256 maxWallet = (s.limitBaseSupply * maxWalletBps) / 10000;

			if (s.balances[user] >= maxWallet) {
				return 0;
			}

			return maxWallet - s.balances[user];
		}

		function getMaxRetailSellAmount(address user) 
		external view returns (uint256) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			bool hasSBT = false;

			if (s.sbtRetailSellRequired) {
				hasSBT = _holdsSBT(user);
			}

			uint256 maxSellBps = hasSBT
				? s.retailSbtSellMaxBps
				: s.retailSellMaxBps;

			if (maxSellBps == 0) {
				return s.balances[user];
			}

			uint256 maxSell = (s.limitBaseSupply * maxSellBps) / 10000;

			return s.balances[user] < maxSell
				? s.balances[user]
				: maxSell;
		}

		function canBuy(address user, uint256 amount)
			external
			view
			returns (bool ok, string memory reason)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			address owner = LibDiamond.contractOwner();

			if (user == address(0)) return (false, "AurionXI: zero address");
			if (amount == 0) return (false, "AurionXI: zero amount");
			if (s.emergencyMode) return (false, "AurionXI: transfers disabled");

			if (s.paused && user != owner) {
				return (false, "AurionXI: transfers paused");
			}

			if (s.blacklistEnabled && s.blacklist[user]) {
				return (false, "AurionXI: blacklisted");
			}

			if (s.antiBotActive && block.timestamp < s.restrictedUntil[user]) {
				return (false, "Wallet temporarily restricted (24h)");
			}

			if (user == owner || _isLimitExempt(user)) {
				return (true, "OK");
			}

			if (s.isInstitutionApproved[user]) {
				if (s.institutionSBTRequired[user]) {
					if (s.sbtContract == address(0)) {
						return (false, "AurionXI: SBT contract not set");
					}

					if (!_holdsSBT(user)) {
						return (false, "AurionXI: Institution requires SBT Verify to buy");
					}
				}

				uint256 instWalletBps = s.institutionMaxWalletBps[user] > 0
					? s.institutionMaxWalletBps[user]
					: s.institutionDefaultMaxWalletBps;

				if (instWalletBps > 0) {
					uint256 maxInstWallet = (s.limitBaseSupply * instWalletBps) / 10000;
					if (s.balances[user] + amount > maxInstWallet) {
						return (false, "AurionXI: Institution buy limit exceeded");
					}
				}

				return (true, "OK");
			}

			bool hasSBT = _hasSBT(user);

			uint256 maxWalletBps = hasSBT
				? s.retailSbtMaxWalletBps
				: s.retailMaxWalletBps;

			if (maxWalletBps > 0) {
				uint256 maxRetailWallet = (s.limitBaseSupply * maxWalletBps) / 10000;
				if (s.balances[user] + amount > maxRetailWallet) {
					return hasSBT
						? (false, "AurionXI: Exceeds AID Retail wallet limit")
						: (false, "AurionXI: Retail wallet limit reached. Verify ID to unlock higher limits.");
				}
			}

			return (true, "OK");
		}


		function canSell(address user, uint256 amount)
			external
			view
			returns (bool ok, string memory reason)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			address owner = LibDiamond.contractOwner();

			if (user == address(0)) return (false, "AurionXI: zero address");
			if (amount == 0) return (false, "AurionXI: zero amount");
			if (s.balances[user] < amount) return (false, "AurionXI: insufficient balance");
			if (s.emergencyMode) return (false, "AurionXI: transfers disabled");

			if (s.paused && user != owner) {
				return (false, "AurionXI: transfers paused");
			}

			if (s.blacklistEnabled && s.blacklist[user]) {
				return (false, "AurionXI: blacklisted");
			}
			
			if (s.antiBotActive && block.timestamp < s.restrictedUntil[user]) {
				return (false, "Wallet temporarily restricted (24h)");
			}

			if (user == owner || _isLimitExempt(user)) {
				return (true, "OK");
			}

			if (s.isInstitutionApproved[user]) {
				if (s.institutionFrozen[user]) {
					return (false, "Wallet Frozen. contact@aurionxi.com");
				}
				
				if (!s.institutionSellEnabled) {
					return (false, "AurionXI: Institutional sell paused");
				}
				
				if (!s.institutionTransferAllowed[user]) {
					return (false, "AurionXI: Institution sell disabled");
				}
				bool institutionNeedsSBT =
					s.institutionSBTRequired[user] ||
					s.sbtInstitutionSellRequired;

				if (institutionNeedsSBT) {
					if (s.sbtContract == address(0)) {
						return (false, "AurionXI: SBT contract not set");
					}

					if (!_holdsSBT(user)) {
						return (false, "AurionXI: Institution must hold SBT to sell");
					}
				}

				uint256 instSellBps = s.institutionSellMaxBps[user] > 0
					? s.institutionSellMaxBps[user]
					: s.institutionDefaultSellMaxBps;

				if (instSellBps > 0) {
					uint256 maxInstSell = (s.limitBaseSupply * instSellBps) / 10000;
					if (amount > maxInstSell) {
						return (false, "AurionXI: Institution sell limit exceeded");
					}
				}

				uint256 cooldownTime = s.institutionSellCooldown[user] > 0
					? s.institutionSellCooldown[user]
					: s.institutionDefaultSellCooldown;

				if (
					cooldownTime > 0 &&
					block.timestamp < s.institutionLastSell[user] + cooldownTime
				) {
					return (false, "AurionXI: Institutional cooldown active");
				}

				return (true, "OK");
			}

			if (!s.retailSellEnabled) {
				return (false, "AurionXI: Retail selling disabled");
			}

			bool hasSBT = false;

			if (s.sbtRetailSellRequired) {
				if (s.sbtContract == address(0)) {
					return (false, "AurionXI: SBT contract not set");
				}

				hasSBT = _holdsSBT(user);

				if (!hasSBT) {
					return (false, "AurionXI: Retail must hold SBT to sell");
				}
			}

			uint256 maxSellBps = hasSBT
				? s.retailSbtSellMaxBps
				: s.retailSellMaxBps;

			if (maxSellBps > 0) {
				uint256 maxRetailSell = (s.limitBaseSupply * maxSellBps) / 10000;
				if (amount > maxRetailSell) {
					return hasSBT
						? (false, "AurionXI: Exceeds SBT retail sell limit")
						: (false, "AurionXI: Exceeds non-SBT sell limit (Get AID)");
				}
			}

			if (
				s.retailSellCooldown > 0 &&
				block.timestamp < s.lastRetailSell[user] + s.retailSellCooldown
			) {
				return (false, "AurionXI: Retail cooldown active. Please wait before next sell.");
			}

			return (true, "OK");
		}
		
		
	
		function getUserTradeVolumes(address user) external view
			returns (uint256 totalTrade, uint256 totalBuy, uint256 totalSell)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return (
				s.totalTradeVolume[user],
				s.totalBuyVolume[user],
				s.totalSellVolume[user]
			);
		}
	}