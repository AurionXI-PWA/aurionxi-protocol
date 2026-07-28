// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ITradeFacet {
    // =============================================================
    // MAIN HOOK (CALLED BY TOKEN FACET)
    // =============================================================
    function validateTrade(
        address from,
        address to,
        uint256 amount
    ) external;

    // =============================================================
    // EVENTS (EMITTED BY TRADE FACET)
    // =============================================================
	 event Transfer(address indexed from, address indexed to, uint256 value);
	 
    event TradeValidationRetail(
        address indexed wallet,
        bool isRetail,
        bool hasSBT,
        uint256 amount,
        uint256 maxBps,
        string tradeType,
        uint256 timestamp
    );

    event TradeValidationInstitution(
        address indexed wallet,
        bool isInstitution,
        uint256 amount,
        uint256 maxBps,
        string tradeType,
        uint256 timestamp
    );

    event SellCooldownRetail(
        address indexed wallet,
        bool isRetail,
        uint256 cooldown,
        uint256 timestamp
    );

    event SellCooldownInstitution(
        address indexed wallet,
        bool isInstitution,
        uint256 cooldown,
        uint256 timestamp
    );
}
