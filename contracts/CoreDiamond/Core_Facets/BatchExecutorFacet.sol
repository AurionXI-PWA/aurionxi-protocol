// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { IBatchExecutor } from "../interfaces/IBatchExecutor.sol";
import { ICoreDiamondCut } from "../interfaces/ICoreDiamondCut.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";


contract BatchExecutorFacet is IBatchExecutor {
			 
		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
		}

    // ============================================================
    // BLOCKED SELECTORS
    // ============================================================
	uint256 private constant MAX_SELECTORS_PER_CHILD_UPGRADE = 50;
	
    bytes4 private constant DIAMOND_CUT_SELECTOR =
        bytes4(
            keccak256(
                "diamondCut((address,uint8,bytes4[])[],address,bytes)"
            )
        );

		bytes4 private constant TRANSFER_OWNERSHIP_SELECTOR =
			bytes4(keccak256("transferOwnership(address)"));
		
		bytes4 private constant OPEN_WINDOW_SELECTOR =
			bytes4(keccak256("openWindow()"));

		bytes4 private constant CLOSE_WINDOW_SELECTOR =
			bytes4(keccak256("closeWindow()"));

		bytes4 private constant CUT_CHILD_SELECTOR =
			bytes4(
				keccak256(
					"cutChildDiamondFacet(uint256,(address,uint8,bytes4[])[],address,bytes)"
				)
			);
		
					
		function _selectorOf(bytes calldata data) internal pure
			returns (bytes4 selector)
		{
			require(data.length >= 4, "CALLDATA_TOO_SHORT");

			assembly {
				selector := calldataload(data.offset)
			}
		}

		function _enforceBatchSelectorGuard(bytes calldata data) 
		internal pure 
		{
			bytes4 selector = _selectorOf(data);

			require(selector != DIAMOND_CUT_SELECTOR, "BATCH_DIAMONDCUT_BLOCKED");
			require(selector != TRANSFER_OWNERSHIP_SELECTOR, "BATCH_OWNER_BLOCKED");
			require(selector != OPEN_WINDOW_SELECTOR, "BATCH_OPEN_WINDOW_BLOCKED");
			require(selector != CLOSE_WINDOW_SELECTOR, "BATCH_CLOSE_WINDOW_BLOCKED");
			require(selector != CUT_CHILD_SELECTOR, "BATCH_CHILD_CUT_BLOCKED");
		}
		
	function _collectSelectors(ICoreDiamondCut.FacetCut[] calldata cut)
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
		require(
			total <= MAX_SELECTORS_PER_CHILD_UPGRADE,
			"CHILD_UPGRADE_RADIUS_EXCEEDED"
		);

		selectors = new bytes4[](total);
		uint256 index;

		for (uint256 i; i < cut.length; ) {
			require(
				cut[i].functionSelectors.length > 0,
				"EMPTY_SELECTOR_SET"
			);

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

		function _resetChildUpgrade(bytes32 upgradeHash) internal {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		delete cs.approvedUpgradeDiff[upgradeHash];

		LibAurionXIStorage.AurionXIStorage storage axs =
			LibAurionXIStorage.aurionxiStorage();

		delete axs.aiApproved[upgradeHash];
		delete axs.firewallApproved[upgradeHash];

		if (axs.aiApprovedHash == upgradeHash) {
			delete axs.aiApprovedHash;
		}

		delete cs.childUpgradeTarget[upgradeHash];
		delete cs.childUpgradeReadyTime[upgradeHash];
		delete cs.childUpgradeExpiryTime[upgradeHash];
		delete cs.childUpgradeQueued[upgradeHash];

		delete cs.approvedSelectors[upgradeHash];
		delete cs.queuedUpgrades[upgradeHash];
		delete cs.upgradeExecutionTime[upgradeHash];

		for (uint256 i; i < cs.guardianList.length; ) {
			address guardian = cs.guardianList[i];

			delete cs.approvedBy[upgradeHash][guardian];
			delete cs.guardianApproved[upgradeHash][guardian];
			delete cs.approved[upgradeHash][guardian];

			unchecked { ++i; }
		}

		delete cs.guardianApprovals[upgradeHash];
		delete cs.approvalCount[cs.guardianApprovalNonce][upgradeHash];

		delete cs.pendingUpgradeHash;
		delete cs.pendingUpgradeIntentHash;
		delete cs.pendingIntent;
		delete cs.pendingUpgradeIntent;
		delete cs.upgradeReadyTime;
		delete cs.proposalExpiryTime;

		cs.guardianApprovalNonce++;
	}
		
		function resetChildUpgradeState(bytes32 upgradeHash) external onlyOwner {
		require(upgradeHash != bytes32(0), "INVALID_UPGRADE_HASH");

		_resetChildUpgrade(upgradeHash);
		
		emit ChildUpgradeStateReset(upgradeHash);
		}
		
	// =====================================================================
	// (BootStrip/Emergency MOde) CUT IMMEDIATE UPGRADE- CHILD DIAMOND FACET DEPLOY
	// =====================================================================

	function cutChildDiamondFacet(
		uint256 index,
		ICoreDiamondCut.FacetCut[] calldata cut,
		address init,
		bytes calldata data
	)
		external
		onlyOwner
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cs.AllowUpgrade, "WINDOW_CLOSED");
		require(cut.length > 0, "EMPTY_CUT");

		address child = _childAt(index);

		ICoreDiamondCut(child).diamondCut(cut, init, data);

		emit ChildDiamondCutExecuted(child, index, init, data);
	}
	
		// ============================================================
		// SCHEDULE CHILD DIAMOND UPGRADE
		// ============================================================
	function scheduleChildUpgrade(
		uint256 index,
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

		address child = _childAt(index);

		bytes32 upgradeHash = keccak256(
			abi.encode(cut, init, data, block.chainid, child)
		);

		bytes4[] memory selectors = _collectSelectors(cut);

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

		cs.childUpgradeTarget[upgradeHash] = child;
		cs.childUpgradeReadyTime[upgradeHash] = cs.upgradeReadyTime;
		cs.childUpgradeExpiryTime[upgradeHash] = cs.proposalExpiryTime;
		cs.childUpgradeQueued[upgradeHash] = true;

		emit ChildUpgradeScheduled(upgradeHash, cs.childUpgradeReadyTime[upgradeHash]);
	}
		
	function isChildUpgradeReady(
		address child,
		bytes32 upgradeHash,
		bytes32 diffHash
	) external view returns (bool) {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		if (!cs.childUpgradeQueued[upgradeHash]) return false;
		if (cs.childUpgradeTarget[upgradeHash] != child) return false;
		if (block.timestamp < cs.childUpgradeReadyTime[upgradeHash]) return false;
		if (block.timestamp > cs.childUpgradeExpiryTime[upgradeHash]) return false;

		if (cs.approvedUpgradeDiff[upgradeHash] != diffHash) return false;

		if (cs.daoEnabled) {
			if (cs.guardianThreshold == 0) return false;

			if (
				cs.approvalCount[cs.guardianApprovalNonce][upgradeHash] <
				cs.guardianThreshold
			) {
				return false;
			}
		}

		LibAurionXIStorage.AurionXIStorage storage axs =
			LibAurionXIStorage.aurionxiStorage();

		if (axs.aiGuardianEnabled && !axs.aiApproved[upgradeHash]) {
			return false;
		}

		if (axs.aiFirewallEnabled && !axs.firewallApproved[upgradeHash]) {
			return false;
		}

		if (axs.aiRiskCheckEnabled && axs.riskScore > axs.maxAllowedRisk) {
			return false;
		}

		return true;
	}
		
	// ---------------------------
	// EXECUTE SCHEDULED UPGRADE
	// ---------------------------
	function executeChildScheduledUpgrade(
		uint256 index,
		ICoreDiamondCut.FacetCut[] calldata cut,
		address init,
		bytes calldata data
	) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cut.length > 0, "EMPTY_CUT");

		address child = _childAt(index);

		bytes32 upgradeHash = keccak256(
			abi.encode(cut, init, data, block.chainid, child)
		);

		require(cs.pendingUpgradeHash == upgradeHash, "UPGRADE_HASH_MISMATCH");
		require(cs.childUpgradeQueued[upgradeHash], "CHILD_UPGRADE_NOT_QUEUED");
		require(cs.childUpgradeTarget[upgradeHash] == child, "CHILD_TARGET_MISMATCH");

		require(
			block.timestamp >= cs.childUpgradeReadyTime[upgradeHash],
			"TIMELOCK_ACTIVE"
		);

		require(
			block.timestamp <= cs.childUpgradeExpiryTime[upgradeHash],
			"PROPOSAL_EXPIRED"
		);

		bytes32 expectedIntentHash = keccak256(
			abi.encode(
				upgradeHash,
				cs.pendingIntent,
				cs.proposalNonce
			)
		);

		require(
			expectedIntentHash == cs.pendingUpgradeIntentHash,
			"INTENT_HASH_MISMATCH"
		);

		ICoreDiamondCut(child).diamondCut(cut, init, data);

		emit ChildScheduledUpgradeExecuted(upgradeHash, child);

		_resetChildUpgrade(upgradeHash);
	}
		
    // ============================================================
    // CHILD DIAMOND Function RUN
    // ============================================================

	function executeBatch(Call[] calldata calls) external onlyOwner {
		for (uint256 i = 0; i < calls.length; i++) {
			_enforceBatchSelectorGuard(calls[i].data);

			(bool success, bytes memory result) =
				calls[i].target.call{value: calls[i].value}(calls[i].data);

			if (!success) {
				if (result.length > 0) {
					assembly {
						let returndata_size := mload(result)
						revert(add(32, result), returndata_size)
					}
				} else {
					revert("BATCH_CALL_FAILED");
				}
			}
		}

		emit BatchExecuted(calls.length);
	}

    //================= VIEW =======================
    function childDiamondAt(uint256 index) external view returns (address) {
        return _childAt(index);
    }
	
    //================= INTERNAL SELECTOR GUARD =====================

	function _childAt(uint256 index ) internal view returns (address child) {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        
		require(index < cs.childDiamonds.length, "INVALID_CHILD_INDEX");
        child = cs.childDiamonds[index];
        require(child != address(0), "CHILD_ZERO");
		
    }
}
