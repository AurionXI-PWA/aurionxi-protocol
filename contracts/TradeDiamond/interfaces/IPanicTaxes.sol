// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IPanicTaxes {
 
    // ==========================================================
    //                    TAX RESULT STRUCT
    // ==========================================================
    // -------------------------------------------------
    // TAX RESULT STRUCT (SINGLE SOURCE OF TRUTH)
    // -------------------------------------------------
    struct TaxResult {
        uint256 totalTax;   // total tax amount
        uint8 taxType; // 0=NONE, 1=NORMAL_BUY, 2=NORMAL_SELL, 3=MICRO_SELL, 4=PANIC_SOFT, 5=PANIC_MEDIUM, 6=PANIC_HARD
    }

    function calculateTaxes(
        address from,
        address to,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) external view returns (TaxResult memory);

 
    // ==========================================================
    //                    OWNER CONFIG
    // ==========================================================
    event SellProtectionUpdated(bool microEnabled, bool panicEnabled);
    event MicroSellShieldUpdated(uint256 minLow, uint256 minHigh, uint256 taxBps);
    event PanicThresholdsUpdated(uint256 softBps, uint256 mediumBps, uint256 hardBps);
    event PanicTaxesUpdated(uint256 softTax, uint256 mediumTax, uint256 hardTax);
    event TaxesUpdated(uint256 buyBps, uint256 sellBps);
	event TaxCapsUpdated(uint256 maxBuyTaxBps, uint256 maxSellTaxBps);
	
	function setTaxCaps(uint256 maxBuyBps, uint256 maxSellBps) external;
    function setSellProtectionEnabled(bool microEnabled, bool panicEnabled) external;
    function setMicroSellShield(uint256 minLowSell, uint256 minHighSell, uint256 microSellTaxBps) external;
    function setPanicThresholds(uint256 softBps, uint256 mediumBps, uint256 hardBps) external;
    function setPanicTaxes(uint256 softTax, uint256 mediumTax, uint256 hardTax) external;
    function setTaxes(uint256 buyBps, uint256 sellBps) external;
 
}