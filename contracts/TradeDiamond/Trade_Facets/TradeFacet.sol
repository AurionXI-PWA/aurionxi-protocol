// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
 
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibCoreStorage.sol";

import "../interfaces/ITradeFacet.sol";
import "../interfaces/IPanicTaxes.sol";
import "../interfaces/ISBT.sol";

contract TradeFacet is ITradeFacet 
	{
	
	function _owner() internal view returns (address) {
        return LibDiamond.contractOwner();
    }
   
	// -------------------------------------------------
    // BUY / SELL DETECTION (CEX + DEX)
    // -------------------------------------------------
    function _isBuy(address from, address /* to */) internal view returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return (from == s.pairAddress || s.isLpPair[from] || s.isMarketPair[from]);
		}
	
	function _isSell(address /* from */, address to) internal view returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return (to == s.pairAddress || s.isLpPair[to] || s.isMarketPair[to]);
		}
	
	function _isLimitExempt(address account) internal view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return (
			s.isExemptFromLimits[account] ||
			s.isExcludedFromLimits[account]
			);
		}

	function validateTrade(address from, address to, uint256 amount) external 
	{
		require(msg.sender == address(this), "TRADE_INTERNAL_ONLY");
		
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
			
		// --------------------------------------------------
		// OWNER FUNDING LP / MARKET (BYPASS ALL RULES)
		// --------------------------------------------------
		if (
			(from == ds.contractOwner || from == s.liquidityLocker) &&
			(to == s.pairAddress || s.isLpPair[to] || s.isMarketPair[to])
			) 
		{
			 // allow ONLY during Unpaused mode
			require(!s.paused, "TOKEN_PAUSED");
			require(!s.emergencyMode, "EMERGENCY_ACTIVE");
			
			s.balances[from] -= amount;
			s.balances[to] += amount;
			emit Transfer(from, to, amount);
			return;
			}

		// --------------------------------------------------
		// GLOBAL SAFETY
		// --------------------------------------------------
		require(!s.emergencyMode, "AurionXI: transfers disabled");

		if (s.paused) {
			require(
				from == ds.contractOwner || to == ds.contractOwner,
				"AurionXI: transfers paused"
			);
		}

		if (s.blacklistEnabled) {
			require(
				!s.blacklist[from] &&
				!s.blacklist[to],
				"AurionXI: blacklisted"
			);
		}

		// =====================================================
		// CEX / EXCHANGE WALLET BYPASS
		// =====================================================
		if (
			s.isExchangeWallet[from] || s.isExchangeWallet[to]
		) {
			require(s.balances[from] >= amount, "AurionXI: insufficient balance");

			s.balances[from] -= amount;
			s.balances[to] += amount;

			emit Transfer(from, to, amount);
			return;
		}

		require(from != address(0) && to != address(0), "AurionXI: zero address");
		require(s.balances[from] >= amount, "AurionXI: insufficient balance");

		// --------------------------------------------------
		// BUY / SELL DETECTION
		// --------------------------------------------------
		bool isBuy  = _isBuy(from, to);
		bool isSell = _isSell(from, to);

		if (isBuy) {
			_validateBuy(from, to, amount, ds.contractOwner);
		} else if (isSell) {
			_validateSell(from, to, amount, ds.contractOwner);
		} else {
			_validateWalletTransfer(from, to, amount, ds.contractOwner);
		}

		// --------------------------------------------------
		// TAX CALCULATION (CALCULATOR ONLY)
		// --------------------------------------------------
		IPanicTaxes.TaxResult memory tax =
			IPanicTaxes(address(this)).calculateTaxes(
				from,
				to,
				amount,
				isBuy,
				isSell
			);

		// --------------------------------------------------
		// APPLY BALANCES (ONCE – SOURCE OF TRUTH)
		// --------------------------------------------------
		
		s.balances[from] -= amount;

		if (tax.totalTax > 0) {
			s.balances[s.feeCollector] += tax.totalTax;
			emit Transfer(from, s.feeCollector, tax.totalTax);
		}

		uint256 sendAmount = amount - tax.totalTax;
		s.balances[to] += sendAmount;
		emit Transfer(from, to, sendAmount);
    
	}
		 
	//===========================================================
    //===================BUY TRANSFER CONTROL
    //===========================================================
     function _validateBuy(address /* from */, address to, uint256 amount, address owner) internal 
	{
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		 	         
		 if (to == owner || _isLimitExempt(to)) return;
		 
		// ---------- INSTITUTION BUY ----------
		
		if (s.isInstitutionApproved[to]) 
		{
			bool institutionNeedsSBT = s.institutionSBTRequired[to];

			if (institutionNeedsSBT) {
				require(
					s.sbtContract != address(0),
					"AurionXI: SBT contract not set"
				);

				require(
					ISBT(s.sbtContract).balanceOf(to) > 0,
					"AurionXI: Institution requires SBT Verify to buy"
				);
			}

			uint256 instWalletBps = s.institutionMaxWalletBps[to] > 0
				? s.institutionMaxWalletBps[to]
				: s.institutionDefaultMaxWalletBps;

			uint256 maxInstWallet = (s.limitBaseSupply * instWalletBps) / 10000;

			if (instWalletBps > 0) {
				require(
					s.balances[to] + amount <= maxInstWallet,
					"AurionXI: Institution buy limit exceeded"
				);
			}

			emit TradeValidationInstitution(
				to,
				true,
				amount,
				instWalletBps,
				"BUY",
				block.timestamp
			);

			return;
		}
	
	// ---------- RETAIL BUY ----------
    if (!s.isInstitutionApproved[to]) 
		{
		// Determine if retail wallet has SBT
	
		bool hasSBT = false;
		
        if (s.sbtCheckEnabled && s.sbtContract != address(0)) {
        hasSBT = ISBT(s.sbtContract).balanceOf(to) > 0;
            }

		//  Select max wallet BPS depending on SBT
        uint256 maxWalletBps = hasSBT 
					? s.retailSbtMaxWalletBps 
					: s.retailMaxWalletBps;

		// logic here    				
		uint256 maxRetailWallet = 
				(s.limitBaseSupply * maxWalletBps) / 10000;
		    
		if (maxWalletBps > 0 && 
			s.balances[to] + amount > maxRetailWallet) 
		{
            revert(hasSBT 
				? "AurionXI: Exceeds AID Retail wallet limit" 
				: "AurionXI: Exceeds Retail wallet limit (Verify ID)"
				);
			}
		}
	}

  
	//===========================================================
    //========  SELL PRE-CHECK (SBT + ENABLE FLAGS)  ============
    //===========================================================
	function _validateSell(address from, address to, uint256 amount,  
													address owner) internal 
	{
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
			if (from == owner || _isLimitExempt(from)) return;
		
    // ---------- INSTITUTION SELL ----------
    if (s.isInstitutionApproved[from]) 
		{
		if (s.institutionFrozen[from]) {
				revert("Wallet Frozen. contact@aurionxi.com");
				}
	
		//-------- Inst Sell Enable on/off -------------------
	    require(
			s.institutionSellEnabled, 
			"AurionXI: Institutional sell paused");
				
		require(
			s.institutionTransferAllowed[from],
			"AurionXI: Institution sell disabled"
		);
		
		bool institutionNeedsSBT =
			s.institutionSBTRequired[from] ||
			s.sbtInstitutionSellRequired;

		if (institutionNeedsSBT) {
			require(
				s.sbtContract != address(0),
				"AurionXI: SBT contract not set"
			);

			require(
				ISBT(s.sbtContract).balanceOf(from) > 0,
				"AurionXI: Institution must hold SBT to sell"
			);
		}

		//--------- Institution Sell Limit ----------------

		uint256 instSellBps = s.institutionSellMaxBps[from] > 0
			? s.institutionSellMaxBps[from]
			: s.institutionDefaultSellMaxBps;

		uint256 maxInstSell = (s.limitBaseSupply * instSellBps) / 10000;

		// 0 = disabled
		if (instSellBps > 0) {
			require(
				amount <= maxInstSell,
				"AurionXI: Institution sell limit exceeded"
			);
		}
        //--------- Institution cooldown----------------
        uint256 cooldownTime = s.institutionSellCooldown[from] > 0
            ? s.institutionSellCooldown[from]
            : s.institutionDefaultSellCooldown;

        if (cooldownTime > 0) {
		require(
			block.timestamp >= s.institutionLastSell[from] + cooldownTime,
			"AurionXI: Institutional cooldown active"
		);
			s.institutionLastSell[from] = block.timestamp;
		}

        emit SellCooldownInstitution(from, true, cooldownTime, block.timestamp);
        emit TradeValidationInstitution(from, true, amount, instSellBps, "SELL", block.timestamp);
		}
	 		
	// ---------- RETAIL SELL ----------
    if (!s.isInstitutionApproved[from]) 
	{		
		//-------------- SELL ENABLE on/off--------------------------
		require(s.retailSellEnabled, "AurionXI: Retail selling disabled");
	   
	   bool hasSBT = false;
        
		if (s.sbtRetailSellRequired) {
			require(s.sbtContract != address(0), "AurionXI: SBT contract not set");
			hasSBT = ISBT(s.sbtContract).balanceOf(from) > 0;
			require(hasSBT, "AurionXI: Retail must hold SBT to sell");
		}
	
		// Select RETAIL MAXBPS depending on SBT 
        uint256 maxSellBps = hasSBT 
						? s.retailSbtSellMaxBps 
						: s.retailSellMaxBps;
        
		uint256 maxRetailSell = (s.limitBaseSupply * maxSellBps) / 10000;
        if (maxSellBps > 0 && 
			amount > maxRetailSell) {
            
			revert(hasSBT 
				? "AurionXI: Exceeds SBT retail sell limit" 
				: "AurionXI: Exceeds non-SBT sell limit (Get AID)");
        }
		
		//====== RETAIL SELL Cooldown =======================
		if (s.retailSellCooldown > 0) {
			require(
				block.timestamp >=
					s.lastRetailSell[from] + s.retailSellCooldown,
				"AurionXI: Retail cooldown active"
			);

			s.lastRetailSell[from] = block.timestamp;
		}

        emit SellCooldownRetail(from, true, s.retailSellCooldown, block.timestamp);
        emit TradeValidationRetail(from, true, hasSBT, amount, maxSellBps, "SELL", block.timestamp);
		}	
	}
		
	//=====================================================================	
	//Wallet → Wallet Transfer Control
	//============================================================
	function  _validateWalletTransfer(
		address from, 
		address to, 
		uint256 amount, 
		address owner) internal 
	{
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (
			from == owner ||
			to == owner ||
			_isLimitExempt(from) ||
			_isLimitExempt(to)
		) {
			return;
		}
		
		// --------------------------------------------------
		// Institution sender checks
		// --------------------------------------------------
		if (s.isInstitutionApproved[from]) {
			if (s.institutionFrozen[from]) {
				revert("Wallet Frozen. contact@aurionxi.com");
			}

			require(
				s.institutionTransferAllowed[from],
				"AurionXI: Institution Transfer Disabled"
			);

			bool institutionNeedsSBT =
				s.institutionSBTRequired[from] ||
				s.sbtInstitutionSellRequired;

			if (institutionNeedsSBT) {
				require(
					s.sbtContract != address(0),
					"AurionXI: SBT contract not set"
				);

				require(
					ISBT(s.sbtContract).balanceOf(from) > 0,
					"AurionXI: Institution must hold SBT to transfer"
				);
			}
		}
		
		 // Institution receiver

		if (s.isInstitutionApproved[to]) 
		{
		uint256 instWalletBps = s.institutionMaxWalletBps[to] > 0
			? s.institutionMaxWalletBps[to]
			: s.institutionDefaultMaxWalletBps;

        uint256 maxInstWallet = (s.limitBaseSupply * instWalletBps) / 10000;
        
		// logic here    
		if (instWalletBps > 0) {
			require(
				s.balances[to] + amount <= maxInstWallet,
				"AurionXI: Institution receiver limit exceeded"
				);
			}
		}
 			
		// Retail receiver  
		
		if (!s.isInstitutionApproved[to]) 
		{
			// Determine if retail wallet has SBT
	
		bool hasSBT = false;
        if (s.sbtCheckEnabled && s.sbtContract != address(0)) {
        hasSBT = ISBT(s.sbtContract).balanceOf(to) > 0;
            }

		//  Select max wallet BPS depending on SBT
        uint256 maxWalletBps = hasSBT 
					? s.retailSbtMaxWalletBps 
					: s.retailMaxWalletBps;
        
		uint256 maxRetailWallet =
    (s.limitBaseSupply * maxWalletBps) / 10000;

		if (
			maxWalletBps > 0 &&
			s.balances[to] + amount > maxRetailWallet
		) {
			revert(
				hasSBT
				? "AurionXI: Exceeds AID Retail wallet TRANSFER limit"
				: "AurionXI: Exceeds Retail wallet to wallet TRANSFER limit (Verify ID)"
			);
		}
       
		}
		
		
		//Retail sender  
		
		if (!s.isInstitutionApproved[from]) {
		
		// Select RETAIL MAXBPS depending on SBT 
        bool hasSBT = false;
			if (s.sbtCheckEnabled && s.sbtContract != address(0)) {
				hasSBT = ISBT(s.sbtContract).balanceOf(from) > 0;
			}
            
		uint256 maxSellBps = hasSBT 
						? s.retailSbtSellMaxBps 
						: s.retailSellMaxBps;
        
		uint256 maxRetailSell =(s.limitBaseSupply * maxSellBps) / 10000;

		if (
			maxSellBps > 0 &&
			amount > maxRetailSell
		) {
			revert(
				hasSBT
				? "AurionXI: Reduce amount. Retail TRANSFER(SEND) ID Limit Exceeds"
				: "AurionXI: Reduce amount, Retail TRANSFER limit. Verify ID to unlock"
				);
				}
			}
		}
  	}
