// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/* ==============================================================
   IFeeFacet.sol — Interface for AurionXI Fee System
   --------------------------------------------------------------
   ✅ Declares all fee-related functions
   ✅ Declares all emitted events
   ✅ Diamond-safe (facet interface only)
   ============================================================== */

interface IFeeFacet {

    // ============================================================
    //                           EVENTS
    // ============================================================
	event ExcludedFromFeeUpdated(address indexed account, bool excluded);
    event ExcludedFromLimitsUpdated(address indexed account, bool excluded);
    event ExemptFromLimitsUpdated(address indexed account, bool exempt);
    event AutomatedMarketMakerPairUpdated(address indexed pair, bool enabled);
	
    /// @notice Wallet lock toggled
    event WalletsLockUpdated(bool locked);

    /// @notice Core wallets updated
    event CoreWalletsUpdated(
        address treasuryWallet,
        address rewardDistributor,
        address liquidityLocker,
        address marketingWallet,
        address burnWallet
    );

    /// @notice Fee split percentages updated (must total 100)
    event FeeSplitWalletUpdated(
        uint256 treasuryShare,
        uint256 rewardShare,
        uint256 liquidityShare,
        uint256 marketingShare,
        uint256 burnShare
    );

    /// @notice Fee distribution executed with detailed breakdown
    event FeeDistributedDetailed(
        uint256 treasuryAmount,
        uint256 rewardAmount,
        uint256 liquidityAmount,
        uint256 marketingAmount,
        uint256 burnAmount,
        uint256 timestamp
    );

    /// @notice Fee collector wallet updated
    event FeeCollectorUpdated(address indexed newCollector);

    /// @notice ERC20 Transfer event (used for fee visibility)
    event Transfer(address indexed from, address indexed to, uint256 value);

		// ============================================================
		//                     GOVERNANCE FUNCTIONS
		// ============================================================

		/// @notice Lock or unlock core wallet updates
		function setWalletsLock(bool locked) external;

		/// @notice Update all core wallets
		function setCoreWalletsUpdated(
			address treasuryWallet,
			address rewardDistributor,
			address liquidityLocker,
			address marketingWallet,
			address burnWallet
		) external;

		/// @notice Configure fee split percentages (must equal 100)
		function setFeeSplitWallet(
			uint256 treasuryShare,
			uint256 rewardShare,
			uint256 liquidityShare,
			uint256 marketingShare,
			uint256 burnShare
		) external;

		/// @notice Set the fee collector wallet
		function setFeeCollector(address collector) external;

		/// @notice Set fee exemption for any address
		function setFeeExempt(address account, bool exempt) external;

		// ============================================================
		//                     FEE EXECUTION
		// ============================================================

		/// @notice Distribute collected fees according to split config
		function distributeFees() external;

		// ============================================================
		//                     VIEW FUNCTIONS
		// ============================================================

		/// @notice Get current fee split percentages
		function getFeeSplit()
			external
			view
			returns (
				uint256 treasuryShare,
				uint256 rewardShare,
				uint256 liquidityShare,
				uint256 marketingShare,
				uint256 burnShare
			);

		function getWalletBalances()
			external
			view
			returns (
				uint256 feeCollectorBalance,
				uint256 treasuryBalance,
				uint256 rewardBalance,
				uint256 liquidityBalance,
				uint256 marketingBalance,
				uint256 burnBalance
			);

		function getAllWalletsAddress()
			external
			view
			returns (
				address feeCollectorWallet,
				address treasuryWallet,
				address rewardWallet,
				address liquidityWallet,
				address marketingWallet,
				address burnWallet     
			);
			 
		
		function setExcludedFromFee(address account, bool excluded) external;

		function setExcludedFromLimits(address account, bool excluded) external;

		function setExemptFromLimits(address account, bool exempt) external;

		function setAutomatedMarketMakerPair(address pair, bool enabled) external;

		function getWalletFlags(address account ) external view
			returns (
				bool feeExempt,
				bool exchangeWallet,
				bool excludedFromFee,
				bool excludedFromLimits,
				bool exemptFromLimits,
				bool automatedMarketMakerPair,
				bool authorizedMinter
			);
		
		
	}
