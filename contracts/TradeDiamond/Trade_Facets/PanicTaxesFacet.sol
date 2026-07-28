// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "../interfaces/IPanicTaxes.sol";

/*
|--------------------------------------------------------------------------
| DYNAMIC TAX POLICY
|--------------------------------------------------------------------------
| Buy and Sell taxes exist to support long-term sustainability of the
| ecosystem and its infrastructure.
|
| Tax rates may be adjusted within predefined protocol limits for:
|
| - Treasury sustainability.
| - Liquidity growth.
| - Marketing initiatives.
| - Ecosystem development.
| - Community incentives.
|
| Tax adjustments should be reasonable, transparent, and always remain
| within the maximum limits defined by the protocol.
|--------------------------------------------------------------------------
*/
/*
|--------------------------------------------------------------------------
| PANIC SELL PROTECTION
|--------------------------------------------------------------------------
| Panic Tax is an anti-manipulation mechanism intended to discourage
| sudden large-scale sell-offs that may destabilize the market.
|
| The feature may activate when predefined abnormal sell thresholds
| are exceeded.
|
| Objectives:
|
| - Reduce extreme market volatility.
| - Protect long-term holders.
| - Discourage coordinated dump attacks.
| - Improve overall market stability.
|
| Panic Tax is not designed to punish ordinary investors, but to
| mitigate exceptional market conditions.
|--------------------------------------------------------------------------
*/
/*
|--------------------------------------------------------------------------
| MICRO SELL PROTECTION
|--------------------------------------------------------------------------
| Micro Sell Protection discourages automated bots from executing
| extremely small repetitive sell transactions intended to manipulate
| price movement or bypass anti-bot rules.
|
| The mechanism helps maintain fair trading conditions for all users.
|--------------------------------------------------------------------------
*/
 
contract PanicTaxesFacet is IPanicTaxes 
	{
		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
		}
 	// ==========================================================
    //              OWNER CONFIGURATION FUNCTIONS
    // ==========================================================
    function setSellProtectionEnabled(bool microEnabled, bool panicEnabled) 
		external override onlyOwner {
        
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        s.microSellEnabled = microEnabled;
        s.panicSellEnabled = panicEnabled;
        
		emit SellProtectionUpdated(microEnabled, panicEnabled);
    }

    function setMicroSellShield(
        uint256 minLowSell,
        uint256 minHighSell,
        uint256 microSellTaxBps
			) external override onlyOwner {
			require(minLowSell < minHighSell, "Invalid range");
			require(microSellTaxBps <= 5000, "Tax too high");

			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			s.minLowSell = minLowSell;
			s.minHighSell = minHighSell;
			s.microSellTaxBps = microSellTaxBps;

			emit MicroSellShieldUpdated(minLowSell, minHighSell, microSellTaxBps);
		}

    function setPanicThresholds(
        uint256 softBps,
        uint256 mediumBps,
        uint256 hardBps
			) external override onlyOwner {
        require(softBps < mediumBps && mediumBps < hardBps, "Invalid order");

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        s.panicSoftBps = softBps;
        s.panicMediumBps = mediumBps;
        s.panicHardBps = hardBps;

        emit PanicThresholdsUpdated(softBps, mediumBps, hardBps);
    }

    function setPanicTaxes(
        uint256 softTax,
        uint256 mediumTax,
        uint256 hardTax
    ) external override onlyOwner {
        require(softTax <= 10000 && mediumTax <= 10000 && hardTax <= 10000, "Max 100%");

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        s.panicSoftTaxBps = softTax;
        s.panicMediumTaxBps = mediumTax;
        s.panicHardTaxBps = hardTax;

        emit PanicTaxesUpdated(softTax, mediumTax, hardTax);
    }
	
	
	function setTaxCaps(uint256 maxBuyBps, uint256 maxSellBps)
		external onlyOwner
	{
		require(maxBuyBps <= 1000, "Buy cap too high");
		require(maxSellBps <= 2000, "Sell cap too high");

		LibAppStorage.AppStorage storage s =
			LibAppStorage.diamondStorage();

		s.maxBuyTaxBps = maxBuyBps;
		s.maxSellTaxBps = maxSellBps;

		emit TaxCapsUpdated(maxBuyBps, maxSellBps);
	}

    function setTaxes(uint256 buyBps, uint256 sellBps) external override onlyOwner {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
        require(buyBps <= s.maxBuyTaxBps, "Buy tax cap");
        require(sellBps <= s.maxSellTaxBps, "Sell tax cap");
		
        s.buyTaxBps = buyBps;
        s.sellTaxBps = sellBps;
        emit TaxesUpdated(buyBps, sellBps);
    }

    
    // ==========================================================
    //                CORE TAX CALCULATOR
    // ==========================================================
    function calculateTaxes(
		address from,
		address to,
		uint256 amount,
		bool isBuy,
		bool isSell
		) external view override returns (TaxResult memory result) 
		{
		
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
			
		
         isSell = (to == s.pairAddress || s.isLpPair[to] || s.isMarketPair[to]);
         isBuy  = (from == s.pairAddress || s.isLpPair[from] || s.isMarketPair[from]);

        // --------------------------------------------------
        // PANIC SELL TAX LOGIC
        // --------------------------------------------------
		 
		uint256 tax;
		bool panicTriggered = false;
		
		if (
			from != ds.contractOwner &&
			!s.isFeeExempt[from] &&
			!s.isFeeExempt[to] &&
			!s.isExcludedFromFee[from] &&
			!s.isExcludedFromFee[to]
			)
		{
			// BUY CONDITION
			if (isBuy && s.buyTaxBps > 0) 
				{
					tax = (amount * s.buyTaxBps) / 10000;
					result.taxType = 1; // NORMAL_BUY
				} 
				
			// --------------------------------------------------
			// MICRO SELL SHIELD
			// --------------------------------------------------
			
			if (isSell && s.microSellEnabled) 
			{
				if (amount < s.minHighSell && amount > s.minLowSell) 
				{
                tax = (amount * s.microSellTaxBps) / 10000;
                panicTriggered = true;
				 
                result.taxType = 3; // MICRO_SELL
				}
			}
			
			//===========================================
			//============ Panic SELL  =================
			//===========================================
			
			if (isSell && s.panicSellEnabled) 
			{
				uint256 supply = s.totalSupply;
				uint256 softAmount   = (supply * s.panicSoftBps) / 10000;
				uint256 mediumAmount = (supply * s.panicMediumBps) / 10000;
				uint256 hardAmount   = (supply * s.panicHardBps) / 10000;
			
				if (amount >= hardAmount) {
					tax = (amount * s.panicHardTaxBps) / 10000;
					panicTriggered = true;
					result.taxType = 6;
				} else if (amount >= mediumAmount) {
					tax = (amount * s.panicMediumTaxBps) / 10000;
					panicTriggered = true;
					result.taxType = 5;
				} else if (amount >= softAmount) {
					tax = (amount * s.panicSoftTaxBps) / 10000;
					panicTriggered = true;
					result.taxType = 4;
				}
			}
			
			// --------------------------------------------------
			// NORMAL TRADE TAX LOGIC
			// --------------------------------------------------
			
			if (!panicTriggered) 
			{		            
				if (isSell && s.sellTaxBps > 0) 
				{
					tax = (amount * s.sellTaxBps) / 10000;
					result.taxType = 2; // NORMAL_SELL
				 
				}
			}

		// --------------------------------------------------
        // -------------ADD TAXES --------------------
        // --------------------------------------------------
        		 
		result.totalTax = tax;
			}
		}
	}

	
 
