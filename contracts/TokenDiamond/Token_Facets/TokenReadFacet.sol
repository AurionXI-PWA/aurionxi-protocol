// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibAppStorage } from "../../libraries/LibAppStorage.sol";

contract TokenReadFacet {

    // ============================================================
    // 🧾 TOKEN CORE INFO (GLOBAL)
    // ============================================================

    function getTokenInfo()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxSupply
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.name,
            s.symbol,
            s.totalSupply,
            s.maxSupply
        );
    }

    // ============================================================
    // 💰 TAX CONFIG
    // ============================================================

    function getTaxInfo()
        external
        view
        returns (
            uint256 buyTaxBps,
            uint256 sellTaxBps
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (s.buyTaxBps, s.sellTaxBps);
    }

    // ============================================================
    // 🏦 WALLET CONFIG
    // ============================================================

    function getWallets()
        external
        view
        returns (
            address feeCollector,
            address treasury,
            address reward,
            address liquidity,
            address marketing,
            address burn
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.feeCollector,
            s.treasuryWallet,
            s.rewardDistributor,
            s.liquidityLocker,
            s.marketingWallet,
            s.burnWallet
        );
    }

    // ============================================================
    // ⚙️ SYSTEM STATUS
    // ============================================================

    function getStatus()
        external
        view
        returns (
            bool paused,
            bool emergencyMode,
            bool initialized,
            bool listingActive,
            uint256 listingTimestamp
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.paused,
            s.emergencyMode,
            s.initialized,
            s.listingActive,
            s.listingTimestamp
        );
    }

    // ============================================================
    // 🌐 GLOBAL FLAGS / LIMITS
    // ============================================================

    function getGlobalFlags()
        external
        view
        returns (
            bool blacklistEnabled,
            uint256 limitBaseSupply
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.blacklistEnabled,
            s.limitBaseSupply
        );
    }

    // ============================================================
    // 👤 USER STATE (PER USER)
    // ============================================================

    function getUserState(address user)
        external
        view
        returns (
            uint256 balance,
            bool isBlacklisted,
            bool isFeeExempt,
            bool isMarketPair,
            bool isLpPair
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.balances[user],
            s.blacklist[user],
            s.isFeeExempt[user],
            s.isMarketPair[user],
            s.isLpPair[user]
        );
    }

    // ============================================================
    // 🔍 QUICK USER VIEW (LIGHTWEIGHT)
    // ============================================================

    function getUserBasic(address user)
        external
        view
        returns (
            uint256 balance,
            bool isBlacklisted
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.balances[user],
            s.blacklist[user]
        );
    }

    // ============================================================
    // 🚀 FULL GLOBAL SNAPSHOT (NO USER)
    // ============================================================

    function getGlobalState()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxSupply,
            uint256 buyTaxBps,
            uint256 sellTaxBps,
            bool paused,
            bool emergencyMode,
            bool initialized
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.name,
            s.symbol,
            s.totalSupply,
            s.maxSupply,
            s.buyTaxBps,
            s.sellTaxBps,
            s.paused,
            s.emergencyMode,
            s.initialized
        );
    }

    // ============================================================
    // 🎯 FULL SNAPSHOT (USER + GLOBAL) → UI FRIENDLY
    // ============================================================

    function getFullState(address user)
        external
        view
        returns (
            // token
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxSupply,

            // tax
            uint256 buyTaxBps,
            uint256 sellTaxBps,

            // status
            bool paused,
            bool emergencyMode,
            bool initialized,
			
			 // wallets
            address feeCollector,
            address treasury,
            address reward,
            address liquidity,
            address marketing,
            address burn,
			
            // user
            uint256 balance,
            bool isBlacklisted,
            bool isFeeExempt
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.name,
            s.symbol,
            s.totalSupply,
            s.maxSupply,
            s.buyTaxBps,
            s.sellTaxBps,
            s.paused,
            s.emergencyMode,
            s.initialized,
			
			// wallets
            s.feeCollector,
            s.treasuryWallet,
            s.rewardDistributor,
            s.liquidityLocker,
            s.marketingWallet,
            s.burnWallet,
			
            s.balances[user],
            s.blacklist[user],
            s.isFeeExempt[user]
        );
    }

    // ============================================================
    // 📊 MULTI USER BALANCE (ADVANCED)
    // ============================================================

    function getBalances(address[] calldata users)
        external
        view
        returns (uint256[] memory balances)
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        balances = new uint256[](users.length);

        for (uint256 i = 0; i < users.length; i++) {
            balances[i] = s.balances[users[i]];
        }
    }
	
	function getPairAddress()
    external
    view
    returns (address)
{
    return LibAppStorage
        .diamondStorage()
        .pairAddress;
}

function isLPPair(address pair)
    external
    view
    returns (bool)
{
    return LibAppStorage
        .diamondStorage()
        .isLpPair[pair];
}


function getPairInfo()
    external
    view
    returns (
        address pair,
        bool lpEnabled,
        bool marketEnabled
    )
{
    LibAppStorage.AppStorage storage s =
        LibAppStorage.diamondStorage();

    pair = s.pairAddress;

    return (
        pair,
        s.isLpPair[pair],
        s.isMarketPair[pair]
    );
}
	
}