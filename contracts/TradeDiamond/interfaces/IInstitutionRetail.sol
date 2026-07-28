// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IInstitutionRetail
 * @notice Interface for InstitutionRetailFacet
 */
interface IInstitutionRetail {
    // =============================================================
    //                          EVENTS
    // =============================================================
	event ExchangeWalletUpdated( address indexed wallet, bool enabled );
    event SellEnabledUpdated(bool retailEnabled, bool institutionEnabled);
	event RetailLimitsUpdated(
		uint256 walletBps,
		uint256 sellBps,
		uint256 cooldown,
		uint256 sbtWalletBps,
		uint256 sbtSellBps
	);
    event InstitutionFrozenUpdated(address indexed wallet, bool frozen);
    event InstitutionConfigUpdated(
        address indexed wallet,
        bool approved,
        uint256 maxWalletBps,
        uint256 maxSellBps,
        uint256 cooldownSeconds,
        bool transferAllowed,
        bool SBTRequired
    );
    event InstitutionStatusUpdated(address indexed wallet, bool approved);
    event InstitutionCooldownTriggered(address indexed wallet, uint256 duration, uint256 timestamp);
  
	event InstitutionDefaultLimitsUpdated(
		uint256 defaultMaxWalletBps,
		uint256 defaultSellMaxBps,
		uint256 defaultCooldown
	);

	
    // =============================================================
    //                          FUNCTIONS
    // =============================================================

    /// @notice Enable or disable retail and institution selling
    function setSellEnabled(bool retailEnabled, bool institutionEnabled) external;

    /// @notice Configure retail limits
    function setRetailLimits(
		uint256 maxWalletBps,
		uint256 sellMaxBps,
		uint256 cooldown,
		uint256 sbtMaxWalletBps,
		uint256 sbtSellMaxBps
	)external;
	
	function setInstitutionDefaultLimits(
		uint256 defaultMaxWalletBps,
		uint256 defaultSellMaxBps,
		uint256 defaultCooldown
	) external;
	
	function approveInstitutionWallet(address wallet, bool approved) external;
	
	/// @notice Freeze or unfreeze an institutional wallet
    function setInstitutionFrozen(address wallet, bool frozen) external;

    /// @notice Configure institution wallet parameters
    function setInstitutionConfig(
        address wallet,
        bool approved,
        uint256 maxWalletBps,
        uint256 maxSellBps,
        uint256 cooldownSeconds,
        bool transferAllowed,
        bool SBTRequired
    ) external;
	
	function getInstitutionStatus(address wallet)
		external view returns (
			bool approved,
			bool frozen,
			uint256 maxWalletBps,
			uint256 maxSellBps,
			uint256 cooldown,
			bool transferAllowed,
			bool sbtRequired
		);
}