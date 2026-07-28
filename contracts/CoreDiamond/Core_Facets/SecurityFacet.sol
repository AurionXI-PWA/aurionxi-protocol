// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";
import { ISecurityFacet } from "../interfaces/ISecurityFacet.sol";

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

contract SecurityFacet is ISecurityFacet {

	//================ MODIFIERS ===========================
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
	
	function approveFacet(address facet) external onlyOwner returns (bool, bytes32) {
		require(facet != address(0), "ZERO");
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		bytes32 codeHash;
		assembly { codeHash := extcodehash(facet) }
		require(codeHash != bytes32(0), "NO_CODE");

		cs.approvedFacets[facet] = true;
		cs.approvedFacetCodeHash[facet] = codeHash;

		emit FacetApproved(facet);

		// Explicit return for verification
		return (cs.approvedFacets[facet], cs.approvedFacetCodeHash[facet]);
	}
	
		
	function approveInit(address init) external onlyOwner {
		require(init != address(0), "ZERO");
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
	
		cs.approvedInits[init] = true;
		emit InitApproved(init);
	}

    function revokeFacetCode(address facet) external onlyOwner {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        delete cs.approvedFacetCodeHash[facet];
    }

    function approveUpgradeDiff(
        bytes32 upgradeHash,
        bytes32 diffHash
		) external onlyOwner {
		
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        cs.approvedUpgradeDiff[upgradeHash] = diffHash;
    }

    function setRequiredSelector(
        bytes4 selector,
        bool status
    ) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        cs.requiredSelectors[selector] = status;
    }

	//=============================================================================
	// VIEW FUNCTION FOR CHILD IMPORT
	//=============================================================================
	function isFacetApproved(address facet) external view returns (bool) {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        return cs.approvedFacets[facet];
    }
	function getFacetCodeHash(address facet) external view returns (bytes32) {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.approvedFacetCodeHash[facet];
	}
	
	function getApprovedFacetData(address facet) external view returns (bool approved, bytes32 codeHash)
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return (cs.approvedFacets[facet], cs.approvedFacetCodeHash[facet] );
	}
	

	function isInitApproved(address init) external view returns (bool) {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.approvedInits[init];
	}
	
	// Upgrade diff approval check
    function isUpgradeDiffApproved(bytes32 upgradeHash, bytes32 diffHash) external view returns (bool) {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        return cs.approvedUpgradeDiff[upgradeHash] == diffHash;
    }

    // Required selector check
    function isSelectorRequired(bytes4 selector) external view returns (bool) {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        return cs.requiredSelectors[selector];
    }
	
	function isSelectorImmutable(bytes4 selector) external view returns (bool)
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.immutableSelectors[selector];
	}

	function isSelectorFrozen(bytes4 selector) external view returns (bool)
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.frozenSelectors[selector];
	}

	function isDeadFacet(address facet) external view returns (bool)
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.deadFacets[facet];
	}

	 
	function setSimulationEnabled(bool enabled) external onlyOwner {
		LibAurionXIStorage.AurionXIStorage storage axs=
			LibAurionXIStorage.aurionxiStorage();

		axs.simulationEnabled = enabled;
	}

	function setAdvancedSecurity(bool enabled) external onlyOwner {
		LibAurionXIStorage.AurionXIStorage storage axs=
			LibAurionXIStorage.aurionxiStorage();

		axs.advancedSecurityEnabled = enabled;
	}
	
	// ============================================================
	// APPROVALS
	// ============================================================
	
	function activateBootstrap(uint256 daysDuration) external onlyOwner
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cs.initialDiamondCutDone, "CUT_NOT_DONE");
		require(!cs.bootstrapUsed, "BOOTSTRAP_ALREADY_USED");
		require(!cs.bootstrapMode, "BOOTSTRAP_ACTIVE");

		require(daysDuration > 0, "INVALID_DURATION");
		require(daysDuration <= 60, "BOOTSTRAP_TOO_LONG");

		cs.bootstrapUsed = true;
		cs.bootstrapMode = true;
		cs.bootstrapUntilTimestamp =
			block.timestamp + daysDuration * 1 days;

		emit BootstrapActivated(cs.bootstrapUntilTimestamp);
	}
	
	function deactivateBootstrap() external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(cs.bootstrapMode, "BOOTSTRAP_INACTIVE");

		cs.bootstrapMode = false;

		emit BootstrapDeactivated();
	}
	
	function isBootstrapUsed() external view returns (bool) {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		return cs.bootstrapUsed;
	}

    // ============================================================
    // 🔹 BOOTSTRAP MODE
    // ============================================================

    function getBootstrapState() external view returns (bool active, uint256 until)
    {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
        return (cs.bootstrapMode, cs.bootstrapUntilTimestamp);
    }


}
