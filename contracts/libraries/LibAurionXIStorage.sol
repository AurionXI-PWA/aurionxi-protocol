// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library LibAurionXIStorage {

    bytes32 constant STORAGE_POSITION =
        keccak256("aurionxi.protocol.storage");

    struct EconomicState {
				uint8 mode; 
				// 0 = normal
				// 1 = accumulation
				// 2 = distribution
				// 3 = panic
				// 4 = recovery

				uint256 riskScore;
				uint256 lastUpdate;
			}

	
	struct AIProposal {
			bytes32 hash;
			uint256 createdAt;
			bool aiApproved;
			bool ownerApproved;
			}
	
    struct UpgradeIntent {

        bytes32 intentHash;
        uint256 createdAt;
        bool simulated;
        bool approved;
    }

    struct AurionXIStorage {

        // ================================
        // AI GUARDIAN
        // ================================
		bool aiGuardianEnabled;
		bool aiFirewallEnabled;
		mapping(bytes32 => bool) firewallApproved;
		bool aiRiskCheckEnabled;
		uint256 riskScore;        // 0 = safe
		uint256 maxAllowedRisk;   // e.g. 30
		bytes32 aiApprovedHash;
        mapping(bytes32 => bool) aiApproved;
        
        // ================================
        // AI SUGGESTIONS
        // ================================

        bool aiSuggestionActive;
        bytes32 aiSuggestedUpgrade;
        uint256 aiConfidenceScore;
        uint256 minConfidenceRequired;

        // ================================
        // MARKET INTELLIGENCE
        // ================================
        bool phase9Enabled;
        bool marketRiskLock;
       
        // ================================
        // IMMUNITY SYSTEM
        // ================================
        bool phase10Enabled;
        bool immunityLock;
        uint256 immunityLevel;
         
      
        // ================================
        // IMMORTAL SELECTORS
        // ================================

        bool phase11Enabled;
        mapping(bytes4 => bool) immortalSelectors;

        // ================================
        // SECURITY TOGGLES
        // ================================
		bool advancedRiskCheck;
        bool advancedSecurityEnabled;
        bool snapshotEnabled;
        bool simulationEnabled;
        bool singleActionRuleEnabled;
        bool deadFacetProtectionEnabled;

    }

    function aurionxiStorage()
        internal
        pure
        returns (AurionXIStorage storage axs)
    {
        bytes32 position = STORAGE_POSITION;

        assembly {
            axs.slot := position
        }
    }
}