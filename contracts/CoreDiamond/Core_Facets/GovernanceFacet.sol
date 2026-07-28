// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { IGovernanceFacet } from "../interfaces/IGovernanceFacet.sol";

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

contract GovernanceFacet is IGovernanceFacet {

		uint256 constant MAX_SELECTORS_PER_UPGRADE = 50;

	//================ MODIFIERS ===========================
	modifier onlyOwner() {
		LibDiamond.enforceIsContractOwner();
		_;
	}

	// Toggle DAO governance
	function setDAOEnabled(bool status) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		cs.daoEnabled = status;
		emit DAOSecurityFlagUpdated("DAOEnabled", status);
	}
	 
	function proposeUpgradeHash(
			bytes32 upgradeHash,
			bytes4[] calldata selectors,
			string calldata intent,
			uint256 delayHours,
			uint256 expiryHours
		) external onlyOwner {

		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(upgradeHash != bytes32(0), "INVALID_HASH");
		require(bytes(intent).length > 10, "INTENT_TOO_SHORT");
		require(selectors.length > 0, "EMPTY_SELECTOR_SET");
		require(selectors.length <= MAX_SELECTORS_PER_UPGRADE, "TOO_MANY_SELECTORS");

		require(cs.pendingUpgradeHash == bytes32(0), "UPGRADE_ALREADY_PENDING");
		cs.proposalNonce++;
		cs.approvedSelectors[upgradeHash] = selectors;
			
		bytes32 intentHash = keccak256(
			abi.encode(upgradeHash, intent, cs.proposalNonce)
		);

		cs.pendingUpgradeHash = upgradeHash;
		cs.pendingUpgradeIntentHash = intentHash;
		cs.pendingIntent = intent;

		uint256 delay = delayHours == 0 ? 24 hours : delayHours * 1 hours;
		uint256 expiry = expiryHours == 0 ? 72 hours : expiryHours * 1 hours;

		require(expiry >= delay, "EXPIRY_BEFORE_TIMELOCK");

		cs.upgradeReadyTime = block.timestamp + delay;
		cs.proposalExpiryTime = block.timestamp + expiry;

		emit UpgradeProposed(
			upgradeHash,
			intentHash,
			intent,
			cs.upgradeReadyTime,
			cs.proposalExpiryTime,
			cs.proposalNonce
			);
		}
		
	function cancelProposal() external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cs.pendingUpgradeHash != bytes32(0), "NO_ACTIVE_PROPOSAL");

		bytes32 oldHash = cs.pendingUpgradeHash;

		delete cs.approvedSelectors[oldHash];
		delete cs.queuedUpgrades[oldHash];
		delete cs.upgradeExecutionTime[oldHash];

		cs.pendingUpgradeHash = bytes32(0);
		cs.pendingUpgradeIntentHash = bytes32(0);
		cs.pendingIntent = "";
		cs.upgradeReadyTime = 0;
		cs.proposalExpiryTime = 0;

		emit ProposalCancelled(oldHash);
		}
	

	
	
	}