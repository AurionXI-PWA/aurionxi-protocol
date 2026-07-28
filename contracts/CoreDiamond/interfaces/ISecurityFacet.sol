// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ISecurityFacet {

		event FacetApproved(address facet);
		event InitApproved(address init);
		event BootstrapActivated(uint256 until);
		event BootstrapDeactivated();
		
		
	function approveFacet(address facet) external returns (bool, bytes32);	
	function approveInit(address init) external;
	function revokeFacetCode(address facet) external;

		function approveUpgradeDiff(
			bytes32 upgradeHash,
			bytes32 diffHash
		) external;

		function setRequiredSelector(
			bytes4 selector,
			bool status
		) external;
		
	//=============================================================================
	// VIEW FUNCTION FOR CHILD IMPORT
	//=============================================================================
	
	function isFacetApproved(address facet) external view returns (bool);
	function getFacetCodeHash(address facet) external view returns (bytes32);
	function getApprovedFacetData(address facet) external view
        returns (bool approved, bytes32 codeHash);
		
	function isInitApproved(address init) external view returns (bool);
    function isUpgradeDiffApproved(bytes32 upgradeHash, bytes32 diffHash) external view returns (bool);
    function isSelectorRequired(bytes4 selector) external view returns (bool);
	
	// ============================================================
    //  (IMPORTANT — GOVERNANCE SYNC)
    // ============================================================
    function isSelectorImmutable(bytes4 selector) external view returns (bool);
    function isSelectorFrozen(bytes4 selector) external view returns (bool);
    function isDeadFacet(address facet) external view returns (bool);
	
	function setSimulationEnabled(bool enabled) external;
	function setAdvancedSecurity(bool enabled) external;
									
	function activateBootstrap(uint256 daysDuration) external;
	function deactivateBootstrap() external;
	
	// ============================================================
    // 🔹 BOOTSTRAP / EMERGENCY
    // ============================================================

    function getBootstrapState() external view 
		returns (bool active, uint256 until);
		
	function isBootstrapUsed() external view returns (bool);

	}