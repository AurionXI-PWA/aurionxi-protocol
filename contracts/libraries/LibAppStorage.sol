// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/* ==============================================================
   LibAppStorage.sol — Shared State Storage for All Facets
   --------------------------------------------------------------
   ✅ Single source of truth for all state variables
   ✅ Shared across ARXITokenFacet, AntiBotFacet, and SBTFacet
   ✅ Prevents storage collisions between Diamond facets
   ✅ Fully compatible with EIP-2535 Diamond Standard
   ==============================================================
*/
//MULTI DIAMOND ORIGINAL
/*
|--------------------------------------------------------------------------
| APPLICATION STORAGE
|--------------------------------------------------------------------------
| Shared storage for all facets.
|
| Storage layout must remain compatible across protocol upgrades.
|--------------------------------------------------------------------------
*/

library LibAppStorage 
	{
    bytes32 internal constant APP_STORAGE_POSITION = keccak256("aurionxi.app.storage");

	 // =============================================================
    //                       STRUCTURE
    // =============================================================
	struct AuditRecord {
        bytes32 facetHash;       // SHA256 hash of facet source
        uint256 score;           // Confidence score (0–100)
        uint8 riskLevel;         // 0=Low, 1=Med, 2=High
        string modelVersion;     // e.g., "AurionAI-v2.1"
        uint256 timestamp;       // When audit was logged
        address auditor;         // Who recorded it
        bool approved;           // Final approval flag
		}
	
	struct Lock {
		uint256 amount;
		uint256 unlockTimestamp;
		}

	struct Proposal {
        uint256 id;
        string description;
        uint256 confidence;
        bool accepted;
        uint256 timestamp;
		uint256 targetDiamondVersion;
		string reason;
		bytes upgradeData;
		bool executed;
		}
	
	struct RiskState {
		uint8 level;
		uint256 panicScore;
		uint256 liquidityRisk;
		}
	
	struct HistoricalState {
		uint256 timestamp;
		uint8 riskLevel;
		uint256 treasuryHealth;
		}

  		// ----------------------------------------------------------
        // Basic ERC20 Data
        // ----------------------------------------------------------
	struct AppStorage {
		
		bool reentrancyLock;
				
		// Global VESTING config
		uint256 globalTGEPercent;        // basis points (1000 = 10%)
		uint256 globalCliffDuration;     // seconds
		uint256 globalVestingDuration;   // seconds
		bool claimPaused;

		// Per-user overrides (Tier system)
		mapping(address => uint256) userTGEPercent;
		mapping(address => uint256) userCliffDuration;
		mapping(address => uint256) userVestingDuration;

		// Core vesting tracking
		mapping(address => uint256) vestingAllocated;
		mapping(address => uint256) vestingClaimed;
		mapping(address => uint256) vestingStartTime;
		
		address owner;
		string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
		bool paused;
		uint256 limitBaseSupply;
	 
        address treasuryWallet;
        address rewardDistributor;
        address liquidityLocker;
        address marketingWallet;
        address burnWallet;
		address feeCollector;
		
		uint256 treasuryShare;
		uint256 rewardShare;
		uint256 liquidityShare;
		uint256 marketingShare;
		uint256 burnShare;
		
        mapping(address => bool) isAdmin;
		
		// LP locking
		mapping(address => Lock) lockedLp;
		bool upgradesFrozen;
		uint256 diamondVersion;
		bool emergencyMode;
		
		
		// ----------------------------------------------------------
		// Initialization Guard
		// ----------------------------------------------------------
		bool initialized;
		bool walletsLocked;
		uint256 maxSupply;
		uint256 maxWalletAmount;
		bool maxTxEnabled;
		uint256 maxTxAmount;
		bool maxWalletEnabled;
		uint256 cooldownSeconds;
		bool cooldownEnabled;
		mapping(address => uint256) lastTxTime;
		
		
		// ----------------------------------------------------------
        // Fee System
        // ----------------------------------------------------------
        uint256 buyTaxBps;
        uint256 sellTaxBps;
		uint256 maxBuyTaxBps;  
		uint256 maxSellTaxBps;
        bool feeEnabled;
        
		mapping(address => bool) isFeeExempt;
		mapping(address => bool) isExchangeWallet;
		mapping(address => bool) isExcludedFromFee;
        mapping(address => bool) isExcludedFromLimits;
        mapping(address => bool) isExemptFromLimits;
		
		mapping(address => bool) automatedMarketMakerPairs;
		mapping(address => bool) isAuthorizedMinter;
		
		// ----------------------------------------------------------
        // LP & Pair Tracking
        // ----------------------------------------------------------
        address pairAddress;
        mapping(address => bool) isLpPair;
        mapping(address => bool) isMarketPair;
		
		uint256 listingTimestamp;
		bool listingActive;
				
		// --- Blacklist management ---
		bool blacklistEnabled;
		mapping(address => bool) blacklist;
 		
        // ----------------------------------------------------------
        // SBT / Identity System
        // ----------------------------------------------------------
        bool sbtCheckEnabled;
		address sbtContract;
                
		bool retailSellEnabled;
		bool institutionSellEnabled;
		
		bool sbtRetailSellRequired;
		bool sbtInstitutionSellRequired;
		
		mapping(address => bool) institutionSBTRequired; 
		address[] institutionList; // <-- track institution addresses
		address[] holders;

		
        // ----------------------------------------------------------
        // Retail & Institutional Config
        // ----------------------------------------------------------
        
        uint256 retailMaxWalletBps;
        uint256 retailSellMaxBps;
        uint256 retailSellCooldown;
        mapping(address => uint256) lastRetailSell;
		
		uint256 retailSbtMaxWalletBps;
		uint256 retailSbtSellMaxBps;
        	
		mapping(address => bool) isInstitutionApproved;
		mapping(address => bool) institutionFrozen;
		mapping(address => bool) institutionTransferAllowed;
		
		mapping(address => uint256) institutionMaxWalletBps;
        mapping(address => uint256) institutionSellMaxBps;
        mapping(address => uint256) institutionSellCooldown;
        mapping(address => uint256) institutionLastSell;
 		
        uint256 institutionDefaultMaxWalletBps;
        uint256 institutionDefaultSellMaxBps;
        uint256 institutionDefaultSellCooldown;
				
		// ----------------------------------------------------------
        // Timestamp Tracking
        // ----------------------------------------------------------
        mapping(address => uint256) lastSellStamp;
		
        // ----------------------------------------------------------
        // Anti-Bot Extension
        // ----------------------------------------------------------
		bool antiBotActive;
		uint256 tradeWindow;
		uint256 maxTradesPerWindow;
		uint256 restrictionDuration;
		
		// =============================================================
		// AntiBot Analytics
		// =============================================================

		mapping(address => uint256) totalTradeVolume;
		mapping(address => uint256) totalBuyVolume;
		mapping(address => uint256) totalSellVolume;

        // ----------------------------------------------------------
        // Panic / Micro Sell Shield
        // ----------------------------------------------------------
        bool panicSellEnabled;
        bool microSellEnabled;
		uint256 minLowSell;
        uint256 minHighSell;
		
		uint256 panicSoftBps;		// soft threshold (basis points of Total supply 100BPS)
        uint256 panicMediumBps;		// medium threshold
        uint256 panicHardBps;		// hard threshold
		
		uint256 panicSoftTaxBps;    // tax applied at soft threshold 30%
		uint256 panicMediumTaxBps; 	// tax applied at medium threshold 60%
		uint256 panicHardTaxBps;  	// tax applied at hard threshold 100%
		uint256 microSellTaxBps;		// tax applied to micro sells 20%

		uint256 panicSellCount;			// total panic sells
        uint256 panicSoftCount;			// count of soft panic sells
		uint256 panicMediumCount;		// count of medium panic sells
		uint256 panicHardCount;			// count of hard panic sells
		uint256 microSellCount;			// count of micro sells detected
		uint256 normalTradeCount;
		
		uint256 totalMicroSellCount;
		uint256 totalPanicSellCount;
		
		uint256 lastMicroSellAmount;	
		uint256 lastPanicSellAmount;	
		uint256 totalNormalTradeCount;

		uint256 totalMicroSellAmount;
		uint256 totalPanicSellAmount;
		uint256 totalNormalTradeAmount;		        		
					
		// Global analytics counters
		uint256 globalTradeCount;       // total trades system-wide
		uint256 dailyTradeVolume;       // total volume per day
		uint256 dailyVolume;            // legacy / daily reset
		uint256 lastResetTimestamp;

		// Per-user analytics
		mapping(address => uint256) userTradeCount;   // total trades per user
		mapping(address => uint256) userTradeVolume;  // volume per user

		// Anti-bot tracking
		mapping(address => uint256) tradeCount;       // trades in current window per user
		mapping(address => uint256) lastTradeTime;
		mapping(address => uint256) restrictedUntil;
		
		bool panicSellTrigger;
		bool microSellTrigger;
		
		// Flags
		bool analyticsInitialized;
		bool analyticsEnabled;
		
		// ------------------------------------------
        // AI / Predictive / Oracle Integration
        // ------------------------------------------
        address aiOracle;
		address aiOracleFacet;
        address aiOracleConnector;
		address integrityFacet;
		address upgradeRegistry;
		
		address aiGovernanceFacet;
		address treasuryContract;
		address governanceRewardContract;
		 
		uint256 proposalCount;
        uint256 aiConfidenceThreshold;
        
		mapping(uint256 => Proposal) proposals;
		mapping(uint256 => mapping(address => bool)) hasVoted;
		mapping(uint256 => uint256) yesVotes;
		mapping(uint256 => uint256) noVotes;
		uint256 governanceMinConfidence;

		mapping(address => AuditRecord) auditRecords;
		mapping(address => uint256) aiWalletScore;
        mapping(address => bool) isAIFrozen;
		
		mapping(address => bool) vestingContracts;
		mapping(address => bool) launchpads;

		 // ------------------------------------------
        // Rewards & Ecosystem Registry
        // ------------------------------------------
        mapping(address => uint256) referralCount;
		mapping(address => uint256) lastRewardClaim;
        
		// ===========================================================
        // Ecosystem Registries
        // =============================================================
        mapping(bytes32 => address) companyRegistry;       // modules keyed by keccak256(name)
        mapping(bytes32 => address) ecosystemRegistry;     // ecosystem modules keyed by keccak256(name)
        mapping(address => bool) authorizedExtensions;     // extension authorization
		mapping(bytes32 => address) analyticsModules;

		address daoGovernor;        // authorized DAO governor
		address dynamicFeeFacet;    // facet allowed to auto-adjust fees
		uint256 globalVersion;
        string metadataURI;


		// =====================================================
		//            ADMIN / STATISTICS
		// =====================================================

		uint256 totalAllocatedTokens;
		uint256 totalClaimedTokens;

		mapping(address => bool) vestingRevoked;
		mapping(address => bool) vestingCancelled;
		
		
		// --- Reserved gap for future upgrades ---
		uint256[100] __gap; // reserve 50 slots
			 
			
	} 
	
	// this last braces is closed app storage
	
	// Accessor for storage
    function diamondStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = keccak256("aurionxi.app.storage");
        assembly { 
		s.slot := position 
		}
	}
		 
	}	 
	
