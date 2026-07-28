// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";

import { IGuardianFacet } from "../interfaces/IGuardianFacet.sol";

contract GuardianFacet is IGuardianFacet {

	//================ MODIFIERS ===========================
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function addGuardian(address g) external onlyOwner {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

        require(g != address(0), "ZERO_ADDRESS");
        require(!cs.guardians[g], "ALREADY_GUARDIAN");

        cs.guardians[g] = true;
        cs.guardianCount++;
    }

    function removeGuardian(address g) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cs.guardians[g], "NOT_GUARDIAN");

		cs.guardians[g] = false;
		cs.guardianCount--;

		if (cs.guardianThreshold > cs.guardianCount) {
			cs.guardianThreshold = cs.guardianCount;
		}

		if (cs.emergencyThreshold > cs.guardianCount) {
			cs.emergencyThreshold = cs.guardianCount;
		}
	}
	
	function setGuardianEnabled(bool enabled) external onlyOwner {
			LibCoreStorage.CoreStorage storage cs =
				LibCoreStorage.coreStorage();

			cs.guardianEnabled = enabled;
		}
	
	function setEmergencyThreshold(uint256 t) external onlyOwner { 
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage(); 
		
		require(t > 0, "INVALID_THRESHOLD"); 
		require(t <= cs.guardianCount, "EXCEEDS_GUARDIANS"); 
	
		cs.emergencyThreshold = t; 
	} 
	
	function approveUpgrade(bytes32 upgradeHash) external {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cs.guardians[msg.sender], "NOT_GUARDIAN");
		require(upgradeHash == cs.pendingUpgradeHash, "INVALID_HASH");
		require(block.timestamp <= cs.proposalExpiryTime, "PROPOSAL_EXPIRED");
		require(!cs.approvedBy[upgradeHash][msg.sender], "ALREADY_APPROVED");

		cs.approvedBy[upgradeHash][msg.sender] = true;
		cs.approvalCount[cs.guardianApprovalNonce][upgradeHash]++;

		emit GuardianApproved(msg.sender, upgradeHash);
	}
	
	function revokeApproval(bytes32 upgradeHash) external  { 
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage(); 
		require(cs.guardians[msg.sender], "NOT_GUARDIAN");
		require(cs.approvedBy[upgradeHash][msg.sender], "NOT_APPROVED"); 

		cs.approvedBy[upgradeHash][msg.sender] = false; 
		cs.approvalCount[cs.guardianApprovalNonce][upgradeHash]--; 
	}

	function approveEmergency() external {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cs.guardianEnabled, "GUARDIAN_DISABLED");
		require(cs.emergencyThreshold > 0, "EMERGENCY_THRESHOLD_NOT_SET");
		require(cs.guardians[msg.sender], "NOT_GUARDIAN");

		uint256 nonce = cs.emergencyNonce;

		require(
			!cs.emergencyApprovedBy[nonce][msg.sender],
			"ALREADY_APPROVED"
		);

		cs.emergencyApprovedBy[nonce][msg.sender] = true;
		cs.emergencyApprovalCount++;

		if (cs.emergencyApprovalCount >= cs.emergencyThreshold) {
			cs.emergencyUpgradeMode = true;
			cs.guardianApprovedEmergency = true;
		}
	}	
	
	//========================================================================
	//=========== Enable advanced institutional security =====================
	//========================================================================
	
	function enableAdvancedSecurity(bool status) external onlyOwner {
		LibAurionXIStorage.AurionXIStorage storage axs = LibAurionXIStorage.aurionxiStorage();
		axs.advancedSecurityEnabled = status;
		emit SecurityFlagUpdated("advancedSecurityEnabled", status);
	}

	function enableAIGuardian(bool status) external onlyOwner {
		LibAurionXIStorage.AurionXIStorage storage axs = LibAurionXIStorage.aurionxiStorage();
		axs.aiGuardianEnabled = status;
		emit SecurityFlagUpdated("aiGuardianEnabled", status);
	}
	
	function setGuardianThreshold(uint256 threshold) external onlyOwner {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

        require(threshold > 0, "INVALID_THRESHOLD");
        require(threshold <= cs.guardianCount, "EXCEEDS_GUARDIANS");

        cs.guardianThreshold = threshold;
		emit GuardianThresholdUpdated(threshold);
    }
	
	function setUpgradeCooldown(uint256 hoursDelay) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		cs.upgradeCooldownHours = hoursDelay;
		emit CooldownUpdated(hoursDelay);
	}

		function resetEmergencyApprovals() external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			cs.guardianApprovedEmergency = false;
			cs.emergencyUpgradeMode = false;
			cs.emergencyApprovalCount = 0;
			cs.emergencyNonce++;
		}
	
	}