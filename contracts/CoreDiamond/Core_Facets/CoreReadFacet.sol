// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";

contract CoreReadFacet {

    // ============================================================
    // 🔹 UPGRADE WINDOW
    // ============================================================

    function isUpgradeWindowOpen() external view returns (bool) {
        return LibCoreStorage.coreStorage().AllowUpgrade;
    }
	
	function isDAOEnabled() external view returns (bool) {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.daoEnabled;
	}
	
    function getProposalNonce() external view returns (uint256) {
        return LibCoreStorage.coreStorage().proposalNonce;
    }
	
    // ============================================================
    // 🔹 EMERGENCY MODE
    // ============================================================

    function isEmergencyMode() external view returns (bool) {
        return LibCoreStorage.coreStorage().emergencyUpgradeMode;
    }

    // ============================================================
    // 🔹 UPGRADE STATE
    // ============================================================

    function getUpgradeState()
        external
        view
        returns (
            bytes32 pendingHash,
            bytes32 intentHash,
            uint256 readyTime,
            uint256 expiryTime
        )
    {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

        return (
            cs.pendingUpgradeHash,
            cs.pendingUpgradeIntentHash,
            cs.upgradeReadyTime,
            cs.proposalExpiryTime
        );
    }

    // ============================================================
    // 🔹 CORE INFO
    // ============================================================

    function getCoreDiamond() external view returns (address) {
        return LibCoreStorage.coreStorage().coreDiamond;
    }

    function getDiamondCount() external view returns (uint256) {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        return cs.diamondCount;
	}

    function getAllChildDiamonds()
        external
        view
        returns (address[] memory)
    {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

        address[] memory diamonds = new address[](cs.childDiamonds.length);

        for (uint256 i; i < cs.childDiamonds.length; i++) {
            diamonds[i] = cs.childDiamonds[i];
        }

        return diamonds;
    }

    function getChildDiamond(uint256 index)
        external
        view
        returns (
            address child,
            string memory name,
            bool registered
        )
    {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

        child = cs.childDiamonds[index];
        name = cs.diamondNames[child];
        registered = cs.registeredDiamonds[child];
    }

    function getChildOwner(address child)
        external
        view
        returns (address)
    {
        return LibCoreStorage.coreStorage().childOwners[child];
    }

    // Check if a child diamond is registered
	function isDiamondRegistered(address child) external view returns (bool) {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.registeredDiamonds[child];
	}

    function isRegistryLocked() external view returns (bool) {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.registryLocked;
	}
	
	function isGuardian(address g) external view returns (bool) {
		return LibCoreStorage.coreStorage().guardians[g];
	}

	function getGuardianCount() external view returns (uint256) {
		return LibCoreStorage.coreStorage().guardianCount;
	}

	function isGuardianEnabled() external view returns (bool) {
		return LibCoreStorage.coreStorage().guardianEnabled;
	}

	function getGuardianThreshold() external view returns (uint256) {
		return LibCoreStorage.coreStorage().guardianThreshold;
	}

	function getEmergencyThreshold() external view returns (uint256) {
		return LibCoreStorage.coreStorage().emergencyThreshold;
	}
	
	function getApprovalCount(bytes32 upgradeHash)
		external
		view
		returns (uint256)
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.approvalCount[cs.guardianApprovalNonce][upgradeHash];
	}

	function hasGuardianApproved(bytes32 upgradeHash, address g)
		external
		view
		returns (bool)
	{
		return LibCoreStorage.coreStorage().approvedBy[upgradeHash][g];
	}
	
	function isAiGuardianEnabled() external view returns (bool) {
		return LibAurionXIStorage.aurionxiStorage().aiGuardianEnabled;
	}

	function isAiFirewallEnabled() external view returns (bool) {
		return LibAurionXIStorage.aurionxiStorage().aiFirewallEnabled;
	}

	function isAiRiskCheckEnabled() external view returns (bool) {
		return LibAurionXIStorage.aurionxiStorage().aiRiskCheckEnabled;
	}

	function isAiApproved(bytes32 upgradeHash) external view returns (bool) {
		return LibAurionXIStorage.aurionxiStorage().aiApproved[upgradeHash];
	}

	function getMaxAllowedRisk() external view returns (uint256) {
		return LibAurionXIStorage.aurionxiStorage().maxAllowedRisk;
	}
	
	function isGuardianEmergencyApproved() external view returns (bool) {
		return LibCoreStorage.coreStorage().guardianApprovedEmergency;
	}
}