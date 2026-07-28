// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library LibCoreStorage {
    bytes32 constant CORE_STORAGE_POSITION = keccak256("aurionxi.core.storage");

			// Voting approval from DAO
	
	enum MarketState { 
				NORMAL, 
				VOLATILE, 
				PANIC, 
				RECOVERY 
				}
				
	enum ImmunityState {
				HEALTHY,
				WARNING,
				DEFENSE,
				LOCKDOWN,
				RECOVERY
			}
	
	struct UpgradeProposal {
    bytes32 upgradeHash;
    bytes32 intentHash;
    string intent;
    uint256 proposalNonce;
    uint256 voteStart;
    uint256 voteEnd;
    bool executed;
}
	
	struct VoteCount {
		uint256 forVotes;
		uint256 againstVotes;
	}
	
	struct TimelockUpgrade {
		bytes32 upgradeHash;
		uint256 executeAfter;
	}
	
	struct SelectorSnapshot {
		bytes4 selector;
		address facet;
		}
		

    struct CoreStorage {
	
		// Owner of CoreDiamond (registry/controller) + Registry lock flag
		
		address coreDiamond;
		bool initialDiamondCutDone;
		bool bootstrapMode;
		
		bool upgradeExecutionLock;
		uint256 riskScore;
		uint256 bootstrapUntilTimestamp;
		address [] coreOwner;
		address owner;
		address registryOwner;
		bool registryLocked;
		uint256 proposalNonce;              // replay protection
		uint256 proposalExpiryTime;         // expiry
		bool guardianApprovedEmergency;
		bool guardianEnabled;
		
		uint256 lastUpgradeTime;
		uint256 upgradeCooldownHours;
	
		mapping(bytes4 => bool) requiredSelectors;
			
		  // ===== Emergency =====
		address[] guardianList;
		bool emergencyUpgradeMode;
		uint256 emergencyThreshold;
		uint256 emergencyApprovalCount;
		mapping(address => bool) guardians;
		
		mapping(address => bool) guardianApproval;
		bool governanceLock;
		uint256 index;
		address[] childDiamonds;
		uint256 diamondCount;
		mapping(address => string) diamondNames;
		mapping(address => address) childOwners;
		mapping(address => bool) registeredDiamonds;
		
		uint256 guardianApprovalNonce;
		uint256 emergencyNonce;
		mapping(uint256 => mapping(address => bool)) emergencyApprovedBy;
		mapping(bytes32 => mapping(address => bool)) guardianApproved;
		
		mapping(bytes32 => mapping(address => bool)) approved;
		mapping(bytes32 => mapping(address => bool)) approvedBy;
		mapping(bytes32 => uint256) guardianApprovals;
		mapping(uint256 => mapping(bytes32 => uint256)) approvalCount;
		uint256 guardianThreshold;
		uint256 minGuardianThreshold;
		uint256 guardianCount;
		mapping(bytes32 => bytes4[]) approvedSelectors;
		
		mapping(bytes32 => bytes32) approvedUpgradeDiff;
		mapping(bytes32 => bool) queuedUpgrades;
		mapping(bytes32 => uint256) upgradeExecutionTime;
		
		mapping(bytes4 => bool) frozenSelectors;
		mapping(address => bool) approvedFacet;
		mapping(bytes4 => bool) immutableSelectors;
		
		mapping(address => bool) deadFacets;
		
		mapping(address => bool) approvedFacets;	
		mapping(address => bytes32) approvedFacetCodeHash;
		mapping(address => bool) approvedInits;
		
		bytes32 pendingUpgradeHash;
		string pendingIntent;
		bool immunityCheck;
		
		bool intentText;
		bytes32 pendingUpgradeIntentHash;
		string pendingUpgradeIntent;
		uint256 securityLevel;
		uint256 minSecurityLevel;
		
		mapping(bytes4 => address) shadowFacet;
		mapping(bytes32 => bool) aiApproved;
		uint256 upgradeReadyTime;
		mapping(bytes32 => uint256) upgradeRisk;
		mapping(bytes4 => address) lastFacetSnapshot;

		mapping(address => mapping(bytes32 => bool)) roles;
		mapping(uint256 => UpgradeProposal) proposals;
		mapping(uint256 => mapping(address => bool)) voted;
		mapping(uint256 => SelectorSnapshot[]) upgradeSnapshots;
		uint256 lastSnapshotId;
		
		
		uint256 marketRiskScore;
		uint256 maxAllowedMarketRisk;
		uint256 lastRiskUpdate;
		
		ImmunityState immunityState;
		MarketState marketState;		
			
		mapping(address => uint8) facetRole;
		bool autoUpgradeAllowed;
		bool approveOwnerHash;
		bool aiModeEnabled;
		bool thresholdGuard;
		
		// ===============================
		// FUTURE SECURITY TOGGLES
		// ===============================
		bool daoEnabled;
		bool upgradeRadiusEnabled;
		
		// ----------------------------------------------------------
		// Child Diamond Scheduled Upgrade Governance
		// ----------------------------------------------------------
		mapping(bytes32 => address) childUpgradeTarget;
		mapping(bytes32 => uint256) childUpgradeReadyTime;
		mapping(bytes32 => uint256) childUpgradeExpiryTime;
		mapping(bytes32 => bool) childUpgradeQueued;

		//============ UpgradeControl Facet Storage ================
		bool AllowUpgrade;
		bool treasuryFrozen;
		bool tradeFrozen;
		address tokenDiamond;    
		mapping(address => uint256) balances;
		mapping(address => uint256) treasuryBalances;
		uint256 maxWithdrawalLimit;
		uint256 totalBalance;
		uint256 treasuryBalance;       // ETH reserves held by TreasuryDiamond
		bool treasuryInitialized;      // one-time initialization flag
		
		// ERC165 supported interfaces
		mapping(bytes4 => bool) supportedInterfaces;
		bytes4 interfaceId;
		
		// registry of child diamonds
		address treasuryDiamond;
        address tradeDiamond;
		address analyticsDiamond;
        address governanceDiamond;
		address aiDiamond;
		
        // Example: system metadata
        uint256 systemVersion;
        string systemName;

        uint256 proposalCount;
		uint256 votingPeriod;
		uint256 quorum;
		bool bootstrapUsed;
		
		// --- Reserved gap for future upgrades ---
		uint256[50] __gap; // reserve 50 slots
				
		
    }

    function coreStorage() internal pure returns (CoreStorage storage cs) {
        bytes32 position = CORE_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}

		