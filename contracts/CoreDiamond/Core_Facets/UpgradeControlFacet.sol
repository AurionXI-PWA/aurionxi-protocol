// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";

import { IUpgradeControlFacet } from "../interfaces/IUpgradeControlFacet.sol";
import { ICoreDiamondCut } from "../interfaces/ICoreDiamondCut.sol";

/*
|--------------------------------------------------------------------------
| ADMINISTRATIVE CONTROLS
|--------------------------------------------------------------------------
| Certain administrative functions exist to ensure protocol security,
| operational continuity, and emergency response capabilities.
|
| Administrative authority should be exercised responsibly and solely
| for protecting the protocol and its users.
|
| Long-term governance decisions may be transitioned to DAO governance
| as the ecosystem matures.
|--------------------------------------------------------------------------
*/

contract UpgradeControlFacet is IUpgradeControlFacet 
	{
		
		//================ MODIFIERS ===========================
		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
			}
		
		// ============================================================
		// UPGRADE WINDOW	Total 11 Function
		// ============================================================

		function openWindow() external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			cs.AllowUpgrade = true;
		}
		
		function closeWindow() external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			cs.AllowUpgrade = false;
		}
		
		function isUpgradeWindow() external view returns (bool){ 
		return LibCoreStorage.coreStorage().AllowUpgrade;	
		}
		
		// ============================================================
		// SCHEDULE CORE UPGRADE
		// ============================================================

	function scheduleCoreUpgrade(
		ICoreDiamondCut.FacetCut[] calldata cut,
		address init,
		bytes calldata data,
		string calldata intent,
		uint256 delayHours,
		uint256 expiryHours
	) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cut.length > 0, "EMPTY_CUT");
		require(bytes(intent).length > 10, "INTENT_TOO_SHORT");
		require(cs.pendingUpgradeHash == bytes32(0), "UPGRADE_ALREADY_PENDING");

		bytes32 upgradeHash = keccak256(
			abi.encode(cut, init, data, block.chainid, address(this))
		);

		bytes4[] memory selectors = _collectCoreSelectors(cut);

		cs.proposalNonce++;

		bytes32 intentHash = keccak256(
			abi.encode(upgradeHash, intent, cs.proposalNonce)
		);

		uint256 delay = delayHours == 0 ? 24 hours : delayHours * 1 hours;
		uint256 expiry = expiryHours == 0 ? 72 hours : expiryHours * 1 hours;

		require(expiry >= delay, "EXPIRY_BEFORE_TIMELOCK");

		cs.pendingUpgradeHash = upgradeHash;
		cs.pendingUpgradeIntentHash = intentHash;
		cs.pendingIntent = intent;

		cs.approvedSelectors[upgradeHash] = selectors;

		cs.upgradeReadyTime = block.timestamp + delay;
		cs.proposalExpiryTime = block.timestamp + expiry;

		cs.queuedUpgrades[upgradeHash] = true;
		cs.upgradeExecutionTime[upgradeHash] = cs.upgradeReadyTime;

		emit CoreUpgradeScheduled(upgradeHash, cs.upgradeReadyTime);
	}
				
	
	function _collectCoreSelectors(
		ICoreDiamondCut.FacetCut[] calldata cut
	)
		internal
		pure
		returns (bytes4[] memory selectors)
	{
		uint256 total;

		for (uint256 i; i < cut.length; ) {
			total += cut[i].functionSelectors.length;
			unchecked { ++i; }
		}

		require(total > 0, "EMPTY_SELECTOR_SET");
		require(total <= 50, "CORE_UPGRADE_RADIUS_EXCEEDED");

		selectors = new bytes4[](total);
		uint256 index;

		for (uint256 i; i < cut.length; ) {
			require(cut[i].functionSelectors.length > 0, "EMPTY_SELECTOR_SET");

			for (uint256 j; j < cut[i].functionSelectors.length; ) {
				bytes4 sel = cut[i].functionSelectors[j];

				for (uint256 k; k < index; ) {
					require(selectors[k] != sel, "DUPLICATE_SELECTOR");
					unchecked { ++k; }
				}

				selectors[index] = sel;
				index++;

				unchecked { ++j; }
			}

			unchecked { ++i; }
		}
	}
	
		// ==============================================================================
		// EXECUTE CORE SCHEDULED UPGRADE via coreDiamondCut.diamondCut(cut, init, data)
		// ==============================================================================
		
	
	// ============================================================
	// EMERGENCY UPGRADE WITHOUT DAO AND FUTURE UPDATE
	// ============================================================
		
		function enableEmergencyMode() external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			
			require(cs.guardians[msg.sender], "NOT_GUARDIAN" );
			cs.emergencyUpgradeMode = true;

			emit EmergencyUpgradeEnabled();
		}

		function disableEmergencyMode() external onlyOwner {
			LibCoreStorage.CoreStorage storage cs =	LibCoreStorage.coreStorage();
			cs.emergencyUpgradeMode = false;

			emit EmergencyUpgradeDisabled();
		}
		
		// ============================================================
		// UPGRADE RESET (INSTITUTIONAL SAFETY)
		// ============================================================
		function resetUpgradeState() external onlyOwner 
		{
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			bytes32 oldHash = cs.pendingUpgradeHash;

			require(oldHash != bytes32(0), "NO_PENDING_UPGRADE");

			delete cs.approvedUpgradeDiff[oldHash];

			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			delete axs.aiApproved[oldHash];
			delete axs.firewallApproved[oldHash];

			if (axs.aiApprovedHash == oldHash) {
				delete axs.aiApprovedHash;
			}

			delete cs.childUpgradeTarget[oldHash];
			delete cs.childUpgradeReadyTime[oldHash];
			delete cs.childUpgradeExpiryTime[oldHash];
			delete cs.childUpgradeQueued[oldHash];

			delete cs.approvedSelectors[oldHash];
			delete cs.queuedUpgrades[oldHash];
			delete cs.upgradeExecutionTime[oldHash];

			for (uint256 i; i < cs.guardianList.length; ) {
				address guardian = cs.guardianList[i];

				delete cs.approvedBy[oldHash][guardian];
				delete cs.guardianApproved[oldHash][guardian];
				delete cs.approved[oldHash][guardian];

				unchecked { ++i; }
			}

			delete cs.guardianApprovals[oldHash];
			delete cs.approvalCount[cs.guardianApprovalNonce][oldHash];

			delete cs.pendingUpgradeHash;
			delete cs.pendingUpgradeIntentHash;
			delete cs.pendingIntent;
			delete cs.pendingUpgradeIntent;
			delete cs.upgradeReadyTime;
			delete cs.proposalExpiryTime;

			cs.guardianApprovalNonce++;

			emit UpgradeStateReset();
		}
	
	


	}
		
		
		
		
		
		
		
		

		
