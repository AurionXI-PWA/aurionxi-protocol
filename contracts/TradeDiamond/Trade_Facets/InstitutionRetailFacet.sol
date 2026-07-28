// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibCoreStorage.sol";
import "../interfaces/IInstitutionRetail.sol";


/* ==============================================================
|   InstitutionRetailFacet — AurionXI Institutional Controls
|   --------------------------------------------------------------
|   ✅ Approve or remove institutional wallets
|   ✅ Assign per-wallet limits (BPS, cooldowns)
|   ✅ Toggle transfer permissions
|   ✅ Supports SBT-based restrictions for compliance
|   ✅ Fully upgradeable under Diamond Standard
|   
|   Institutional selling controls help manage large-volume transactions
|	that could significantly impact market stability.
|	Restrictions may be applied during:
|
| - Major liquidity events.
| - Security incidents.
| - Market manipulation attempts.
| - Treasury protection scenarios.
|
| These controls are intended solely to reduce systemic risk and not to
| unfairly restrict legitimate institutional participants.
   ============================================================== */
/*
|--------------------------------------------------------------------------
| RETAIL SELL CONTROL
|--------------------------------------------------------------------------
| Retail selling may be temporarily disabled only when abnormal market
| conditions threaten ecosystem stability.
|
| Examples:
|
| - Coordinated bot attacks.
| - Flash-loan manipulation.
| - Network instability.
| - Severe exploit attempts.
|
| This feature is designed to protect genuine holders and should never
| be used to unfairly prevent normal market participation.
|--------------------------------------------------------------------------
*/

contract InstitutionRetailFacet is IInstitutionRetail {

		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
		}	
	
    // ===============================================
    // Enable / Disable retail + institution selling
    // ===============================================
    function setSellEnabled(bool retailEnabled, bool institutionEnabled) 
	external override onlyOwner {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        s.retailSellEnabled = retailEnabled;
        s.institutionSellEnabled = institutionEnabled;
        emit SellEnabledUpdated(retailEnabled, institutionEnabled);
    }

    // ===============================================
    // Retail limits configuration
    // ===============================================
    function setRetailLimits(
		uint256 maxWalletBps,
		uint256 sellMaxBps,
		uint256 cooldown,
		uint256 sbtMaxWalletBps,
		uint256 sbtSellMaxBps
	) external override onlyOwner {
		require(
			maxWalletBps <= 10000 &&
			sellMaxBps <= 10000 &&
			sbtMaxWalletBps <= 10000 &&
			sbtSellMaxBps <= 10000,
			"Invalid Bps value"
		);

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		s.retailMaxWalletBps = maxWalletBps;
		s.retailSellMaxBps = sellMaxBps;
		s.retailSellCooldown = cooldown;

		s.retailSbtMaxWalletBps = sbtMaxWalletBps;
		s.retailSbtSellMaxBps = sbtSellMaxBps;

		emit RetailLimitsUpdated(
			maxWalletBps,
			sellMaxBps,
			cooldown,
			sbtMaxWalletBps,
			sbtSellMaxBps
		);
	}

    // ===============================================
    // Freeze or unfreeze an institutional wallet
    // ===============================================
    function setInstitutionFrozen(address wallet, bool frozen) 	
		external override onlyOwner {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        s.institutionFrozen[wallet] = frozen;
        emit InstitutionFrozenUpdated(wallet, frozen);
    }

    // ===============================================
    // Institutional wallet configuration
    // ===============================================
    function setInstitutionConfig(
        address wallet,
        bool approved,
        uint256 maxWalletBps,
        uint256 maxSellBps,
        uint256 cooldownSeconds,
        bool transferAllowed,
        bool SBTRequired
		) 	
		external override onlyOwner {
        require(wallet != address(0), "Invalid wallet");
        require(maxWalletBps <= 10000 && maxSellBps <= 10000, "Invalid Bps value");

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
       
		bool wasApproved = s.isInstitutionApproved[wallet];

		s.isInstitutionApproved[wallet] = approved;
		s.institutionMaxWalletBps[wallet] = maxWalletBps;
		s.institutionSellMaxBps[wallet] = maxSellBps;
		s.institutionSellCooldown[wallet] = cooldownSeconds;
		s.institutionTransferAllowed[wallet] = transferAllowed;
		s.institutionSBTRequired[wallet] = SBTRequired;

		if (approved && !wasApproved) {
			bool exists = false;

			for (uint256 i = 0; i < s.institutionList.length; i++) {
				if (s.institutionList[i] == wallet) {
					exists = true;
					break;
				}
			}

			if (!exists) {
				s.institutionList.push(wallet);
			}
		}

		emit InstitutionConfigUpdated(
			wallet,
			approved,
			maxWalletBps,
			maxSellBps,
			cooldownSeconds,
			transferAllowed,
			SBTRequired
		);
    }
	
	 
	//======================================
	// Institution DEFAULT LIMITES
	//======================================
	function setInstitutionDefaultLimits(
		uint256 defaultMaxWalletBps,
		uint256 defaultSellMaxBps,
		uint256 defaultCooldown
	) external override onlyOwner {
		require(
			defaultMaxWalletBps <= 10000 &&
			defaultSellMaxBps <= 10000,
			"Invalid Bps value"
		);

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		s.institutionDefaultMaxWalletBps = defaultMaxWalletBps;
		s.institutionDefaultSellMaxBps = defaultSellMaxBps;
		s.institutionDefaultSellCooldown = defaultCooldown;

		emit InstitutionDefaultLimitsUpdated(
			defaultMaxWalletBps,
			defaultSellMaxBps,
			defaultCooldown
		);
	}

	function approveInstitutionWallet(address wallet, bool approved)
		external override onlyOwner
	{
		require(wallet != address(0), "Invalid wallet");

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		bool wasApproved = s.isInstitutionApproved[wallet];
		s.isInstitutionApproved[wallet] = approved;

		if (approved && !wasApproved) {
			bool exists = false;

			for (uint256 i = 0; i < s.institutionList.length; i++) {
				if (s.institutionList[i] == wallet) {
					exists = true;
					break;
				}
			}

			if (!exists) {
				s.institutionList.push(wallet);
			}
		}

		emit InstitutionStatusUpdated(wallet, approved);
	}

    // ===============================================
    // Institution view helpers
    // ===============================================
    function getInstitutionStatus(address wallet)
		external view override returns (
			bool approved,
			bool frozen,
			uint256 maxWalletBps,
			uint256 maxSellBps,
			uint256 cooldown,
			bool transferAllowed,
			bool sbtRequired
		)
	{
		LibAppStorage.AppStorage storage s =
			LibAppStorage.diamondStorage();

		return (
			s.isInstitutionApproved[wallet],
			s.institutionFrozen[wallet],
			s.institutionMaxWalletBps[wallet],
			s.institutionSellMaxBps[wallet],
			s.institutionSellCooldown[wallet],
			s.institutionTransferAllowed[wallet],
			s.institutionSBTRequired[wallet]
		);
	}

	function isInstitutionApproved(address wallet) external view returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.isInstitutionApproved[wallet];
    }

    function getInstitutionLastSell(address wallet) external view returns (uint256) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.institutionLastSell[wallet];
    }

    function canInstitutionTransfer(address wallet) external view returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.institutionTransferAllowed[wallet];
    }

    // ===============================================
    // control helpers
    // ===============================================
    function setInstitutionCooldown(address wallet, uint256 cooldownSeconds)
		external  onlyOwner
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		require(wallet != address(0), "ZERO_ADDRESS");
		require(
			s.isInstitutionApproved[wallet],
			"NOT_INSTITUTION"
		);
		s.institutionSellCooldown[wallet] = cooldownSeconds;
	}

    function viewWalletBalance(address account) external view onlyOwner 
		returns (uint256) {
        
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return s.balances[account];
    }

    function viewAllWallets() external view onlyOwner 
		returns (address[] memory, uint256[] memory) {
        
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.holders.length;

        address[] memory accounts = new address[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            accounts[i] = s.holders[i];
            amounts[i] = s.balances[accounts[i]];
        }

        return (accounts, amounts);
    }

    function getInstitutionConfig(address wallet) external view returns (
            bool approved,
            uint256 maxWalletBps,
            uint256 maxSellBps,
            uint256 cooldownSeconds,
            bool transferAllowed,
            bool SBTRequired
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return (
            s.isInstitutionApproved[wallet],
            s.institutionMaxWalletBps[wallet],
            s.institutionSellMaxBps[wallet],
            s.institutionSellCooldown[wallet],
            s.institutionTransferAllowed[wallet],
            s.institutionSBTRequired[wallet]
        );
    }

    function getAllInstitutions() external view onlyOwner returns (
            address[] memory wallets,
            bool[] memory approved,
            uint256[] memory maxWalletBps,
            uint256[] memory maxSellBps,
            uint256[] memory cooldownSeconds,
            bool[] memory transferAllowed,
            bool[] memory SBTRequired
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.institutionList.length;

        wallets = new address[](length);
        approved = new bool[](length);
        maxWalletBps = new uint256[](length);
        maxSellBps = new uint256[](length);
        cooldownSeconds = new uint256[](length);
        transferAllowed = new bool[](length);
        SBTRequired = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            address inst = s.institutionList[i];
            wallets[i] = inst;
            approved[i] = s.isInstitutionApproved[inst];
            maxWalletBps[i] = s.institutionMaxWalletBps[inst];
            maxSellBps[i] = s.institutionSellMaxBps[inst];
            cooldownSeconds[i] = s.institutionSellCooldown[inst];
            transferAllowed[i] = s.institutionTransferAllowed[inst];
            SBTRequired[i] = s.institutionSBTRequired[inst];
        }

        return (wallets, approved, maxWalletBps, maxSellBps, cooldownSeconds, transferAllowed, SBTRequired);
    }
	
	
		function setExchangeWallet(address wallet, bool enabled )
			external onlyOwner
		{
			require(wallet != address(0), "ZERO_ADDRESS");
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.isExchangeWallet[wallet] = enabled;

			emit ExchangeWalletUpdated( wallet, enabled );
		}

		function isExchangeWallet(address wallet) external view returns (bool)
		{
			return LibAppStorage.diamondStorage().isExchangeWallet[wallet];
		}

}