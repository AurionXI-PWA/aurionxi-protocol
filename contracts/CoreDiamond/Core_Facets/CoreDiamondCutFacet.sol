// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/*
============================================================================	
	Project: “Professional-Grade Modular EIP-2535 System Protocol”
	Author: Mr. RajGuru (I Am The Best)
	Website: www.aurionxi.com
	
=============================================================================*/

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";
import "../interfaces/ICoreDiamondCut.sol";
import "../interfaces/ICoreDiamond.sol";

import "../../TradeDiamond/interfaces/ITradeFacet.sol";
import "../../TokenDiamond/interfaces/IERC20Facet.sol";
import "../interfaces/IERC165Facet.sol";

/*
|--------------------------------------------------------------------------
| UPGRADE POLICY
|--------------------------------------------------------------------------
| Diamond upgrades allow protocol improvements, bug fixes and
| security enhancements while preserving persistent storage.
|
| Upgrade authority should only be exercised responsibly and
| in the best interest of the ecosystem.
|--------------------------------------------------------------------------
*/

contract CoreDiamondCutFacet is ICoreDiamondCut 
	{

    string public constant PROTOCOL = "AurionXI Professional-Grade Modular EIP-2535 Protocol";
    string public constant AUTHOR = "RajGuru";
    string public constant VERSION = "AurionXI V1";

    uint256 constant MAX_SELECTORS_PER_UPGRADE = 50;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function _owner() internal view returns (address) {
        return LibDiamond.contractOwner();
    }

    // ============================================================
    // MAIN CONTROLLER (MODULAR)
    // ============================================================

    function diamondCut(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    )
        external
        override
        onlyOwner
    {
        require(_cut.length > 0,"EMPTY_UPGRADE");
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		
		// ============================================================
		// FIRST DIAMOND CUT (NO SECURITY CHECKS)
		// ============================================================
		
		if(!cs.initialDiamondCutDone){

			_executeDiamondCut(_cut, _init, _calldata);
			cs.initialDiamondCutDone = true;
		
			return;
		}
		
		// ============================================================
		// MODE DETECTION
		// ============================================================

		Mode mode = _getMode(cs);

		// ============================================================
		// BASIC SAFETY (ALWAYS ON — EVEN IN BOOTSTRAP)
		// ============================================================
		
		// ============================================================
		// 1. AUTO SYNC
		// ============================================================

		for (uint256 i; i < _cut.length; i++) {
			if (_cut[i].action != FacetCutAction.Remove) {
				_autoSyncFacet(_cut[i].facetAddress);
			}
		}

		if (_init != address(0)) {
			_autoSyncInit(_init);
		}

		// ============================================================
		// 2. LOCAL VALIDATION
		// ============================================================

		for (uint256 i; i < _cut.length; i++) {
			address facet = _cut[i].facetAddress;

			if (_cut[i].action != FacetCutAction.Remove) {
				_verifyFacetIntegrity(facet);
			}

			require(_cut[i].functionSelectors.length > 0, "EMPTY_SELECTOR_SET");
		}


		// ============================================================
		// HASHES (needed for higher modes)
		// ============================================================

        bytes32 upgradeHash = _computeUpgradeHash(_cut,_init,_calldata);
        bytes32 intentHash = _computeIntentHash(upgradeHash);
		bytes32 diffHash = _computeDiffHash(_cut);
		
		
		
		// ============================================================
		// BOOTSTRAP MODE
		// ============================================================

		if (mode == Mode.BOOTSTRAP) {

			// only basic safety applied
			_executeDiamondCut(_cut, _init, _calldata);
			_postExecutionCleanup(cs, upgradeHash, false);

			return;
		}

		// ============================================================
		// EMERGENCY MODE (PARTIAL SECURITY)
		// ============================================================

		if (mode == Mode.EMERGENCY) {

			// light protection only
			_checkDuplicateSelectors(_cut);
			_validateCriticalSelectorChanges(_cut);
			_checkSelectorCollision(_cut);

			_executeDiamondCut(_cut, _init, _calldata);
			_postExecutionCleanup(cs, upgradeHash, true);

			return;
		}
		
		// ============================================================
		// PRODUCTION MODE (FULL SECURITY)
		// ============================================================
		
		if (_isCoreGovernedChildUpgrade(cs, upgradeHash, diffHash)) {
			_validateCoreGovernedChildSecurity(
				cs,
				upgradeHash,
				diffHash,
				_cut,
				_init
			);

			_executeDiamondCut(_cut, _init, _calldata);

			return;
		}
				
		_validateFacetSafety(_cut);
		_validateCriticalSelectorChanges(_cut);
		
		
		// ============================================================
		// 3. CORE VALIDATIONS
		// ============================================================

		// selectors check
		for (uint256 i; i < _cut.length; i++) {
			bytes4[] calldata selectors = _cut[i].functionSelectors;

			for (uint256 j; j < selectors.length; j++) {
				if (_isSelectorRequired(selectors[j])) {
					// optional logic
				}
			}
		}
 
		_validateTimelockGovernance(
			cs,
			upgradeHash,
			intentHash,
			_init
		);
		
		
		_validateDAOGovernance(
			cs,
			upgradeHash
		);

		_validateAIGuardian(
			cs,
			upgradeHash,
			_cut
		);
		
		
        // ============================================================
		// Layer 5 — Institutional Security
		// ============================================================
	   
        _runInstitutionalSecurity(
			cs,
			_cut
		);

        // ============================================================
		// Base Security Pipeline
		// ============================================================

        _runSecurityPipeline(
			cs,
			upgradeHash,
			diffHash,
			_cut
		);
 
        // ============================================================
		// Execute Upgrade
		// ============================================================
        
		_executeDiamondCut(
			_cut,
			_init,
			_calldata
		);
		
        // ============================================================
		// Cleanup
		// ============================================================

        _postExecutionCleanup(
            cs,
            upgradeHash,
            false
        );
		
    }
	
    // ============================================================
    // HASH MODULE
    // ============================================================

    function _computeUpgradeHash(
        FacetCut[] calldata _cut,
        address _init,
        bytes calldata _calldata
    )
        internal
        view
        returns(bytes32)
    {
        return keccak256(
            abi.encode(
                _cut,
                _init,
                _calldata,
                block.chainid,
                address(this)
            )
        );
    }

    function _computeIntentHash(bytes32 upgradeHash)
        internal
        view
        returns(bytes32)
    {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();				
        return keccak256( abi.encode(
                upgradeHash,
                cs.pendingIntent,
                cs.proposalNonce
            )
        );
    }

	function _validateCriticalSelectorChanges(FacetCut[] calldata _cut)
		internal
		pure
	{
		for (uint256 i; i < _cut.length; ) {
			for (uint256 j; j < _cut[i].functionSelectors.length; ) {
				bytes4 sel = _cut[i].functionSelectors[j];

				require(
					sel != ICoreDiamondCut.diamondCut.selector,
					"DIAMONDCUT_PROTECTED"
				);

				if (_isCriticalSelector(sel)) {
					require(
						_cut[i].action == FacetCutAction.Add,
						"CRITICAL_SELECTOR_CHANGE_BLOCKED"
					);
				}

				unchecked { ++j; }
			}

			unchecked { ++i; }
		}
	}
	
	function _validateCoreGovernedChildSecurity(
		LibCoreStorage.CoreStorage storage cs,
		bytes32 upgradeHash,
		bytes32 diffHash,
		FacetCut[] calldata _cut,
		address _init
	)
		internal
		view
	{
		require(
			ICoreDiamond(cs.coreDiamond).isUpgradeDiffApproved(
				upgradeHash,
				diffHash
			),
			"UPGRADE_DIFF_NOT_APPROVED"
		);

		if (_init != address(0)) {
			require(_hasCode(_init), "INIT_NO_CODE");
		}

		require(!_isPhantomReplace(_cut), "PHANTOM_UPGRADE");

		_checkUpgradeRadius(_cut);
		_checkDuplicateSelectors(_cut);
		_validateFacetSafety(_cut);
		_validateCriticalSelectorChanges(_cut);
		_checkSelectorCollision(_cut);
		_checkCriticalSelectors(_cut);
		_checkFacetDependencies(_cut);
		_validateSelectors(_cut);
		_simulateCut(_cut);
	}
    // ============================================================
    // LAYER 1 — FACET SAFETY
    // ============================================================
	function _autoSyncFacet(address facet) internal {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		// already approved locally → skip
		if (cs.approvedFacets[facet]) return;

		address core = cs.coreDiamond;
		require(core != address(0), "CORE_NOT_SET");

		(bool approved, bytes32 codeHash) =
			ICoreDiamond(core).getApprovedFacetData(facet);

		require(approved, "FACET_NOT_APPROVED_IN_CORE");

		// store locally
		cs.approvedFacets[facet] = true;
		cs.approvedFacetCodeHash[facet] = codeHash;
	}
	
    function _validateFacetSafety(FacetCut[] calldata _cut)
        internal view
    {
        LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
				
        for(uint256 i; i < _cut.length; )
		{	
            bytes4[] calldata selectors = _cut[i].functionSelectors;
			
            for(uint256 j; j < selectors.length; ){
                bytes4 sel = selectors[j];
				
				require(
					!ICoreDiamond(cs.coreDiamond).isSelectorImmutable(sel),
					"IMMUTABLE_SELECTOR"
				);
				require(
					!ICoreDiamond(cs.coreDiamond).isSelectorFrozen(sel),
					"SELECTOR_FROZEN" 
				);
					
					unchecked{++j;}
			}

            if(_cut[i].action == FacetCutAction.Remove){
                for(uint256 j; j < selectors.length; ){
					
						require(
							!_isCriticalSelector(selectors[j]),
                        "PROTOCOL_DEATH_SWITCH"
						);
                    unchecked{++j;}
                }
            }
            unchecked{++i;}
        }
		
    }


    // ============================================================
    // LAYER 2 — TIMELOCK GOVERNANCE
    // ============================================================
	function _isCoreGovernedChildUpgrade(
		LibCoreStorage.CoreStorage storage cs,
		bytes32 upgradeHash,
		bytes32 diffHash
	) internal view returns (bool) {
		if (address(this) == cs.coreDiamond) {
			return false;
		}

		if (msg.sender != cs.coreDiamond) {
			return false;
		}

		return ICoreDiamond(cs.coreDiamond).isChildUpgradeReady(
			address(this),
			upgradeHash,
			diffHash
		);
	}

    function _validateTimelockGovernance(
        LibCoreStorage.CoreStorage storage cs,
        bytes32  upgradeHash,
        bytes32 intentHash,
        address _init
    )
        internal view
    {
        require(cs.pendingUpgradeHash != bytes32(0),
            "NO_PENDING_PROPOSAL"
        );

        require(cs.pendingUpgradeIntentHash != bytes32(0),
            "INTENT_NOT_SET"
        );

        require(block.timestamp <= cs.proposalExpiryTime,
            "PROPOSAL_EXPIRED"
        );
		require(upgradeHash == cs.pendingUpgradeHash,
			"UPGRADE_HASH_MISMATCH"
		);

        require(intentHash == cs.pendingUpgradeIntentHash,
            "INTENT_MISMATCH"
        );

        require(block.timestamp >= cs.upgradeReadyTime,
			"TIMELOCK_ACTIVE"
		);

        require(
            block.timestamp >
            cs.lastUpgradeTime +
            cs.upgradeCooldownHours * 1 hours,
            "UPGRADE_COOLDOWN"
        );
		
        if(_init != address(0)){
            require(_hasCode(_init), "INIT_NO_CODE" );
			}
    }

    // ============================================================
    // LAYER 3 — DAO GOVERNANCE
    // ============================================================
    function _validateDAOGovernance(
        LibCoreStorage.CoreStorage storage cs,
        bytes32 upgradeHash
    )
        internal
        view
    {
        if(!cs.daoEnabled) return;
        
        require( cs.approvalCount[cs.guardianApprovalNonce][upgradeHash]
            >= cs.guardianThreshold,
            "INSUFFICIENT_GUARDIAN_APPROVALS"
        );
        require( cs.queuedUpgrades[upgradeHash],
            "UPGRADE_NOT_QUEUED"
        );

        require(block.timestamp >=
            cs.upgradeExecutionTime[upgradeHash],
            "EXECUTION_TIME_NOT_REACHED"
        );

        require( cs.guardianThreshold >=
            cs.minGuardianThreshold,
            "GOVERNANCE_DRIFT_BLOCKED"
        );
    }

	
    // ============================================================
    // LAYER 4 — AI GUARDIAN
    // ============================================================

    function _validateAIGuardian(
        LibCoreStorage.CoreStorage storage cs,
        bytes32 upgradeHash,
        FacetCut[] calldata _cut
    )
        internal
        view
    {
		LibAurionXIStorage.AurionXIStorage storage axs =
						LibAurionXIStorage.aurionxiStorage();
        if (axs.aiGuardianEnabled) {
            require(
                axs.aiApproved[upgradeHash],
                "AI_NOT_APPROVED"
            );
        }

        if (axs.aiFirewallEnabled) {
            require(
                axs.firewallApproved[upgradeHash],
                "AI_FIREWALL_BLOCKED"
            );
        }

        if (axs.aiRiskCheckEnabled) {
            require(
                axs.riskScore <= axs.maxAllowedRisk,
                "AI_RISK_TOO_HIGH"
            );
        }

        if (axs.deadFacetProtectionEnabled) {
		
            for (uint256 i; i < _cut.length; ) {
			
               address facet = _cut[i].facetAddress;
			   require(
					!ICoreDiamond(cs.coreDiamond).isDeadFacet(facet),
					"DEAD_FACET_BLOCKED"
				);
                unchecked { ++i; }
            }
        }

        if (axs.aiSuggestionActive) {
            require(
                upgradeHash == axs.aiSuggestedUpgrade,
                "NOT_AI_SUGGESTED"
            );
            require(
                axs.aiConfidenceScore >=
                axs.minConfidenceRequired,
                "AI_CONFIDENCE_LOW"
            );
        }

        if (axs.phase9Enabled) {
            require(
                !axs.marketRiskLock,
                "MARKET_RISK_LOCK"
            );
        }

        if (axs.phase10Enabled) {
            require(
                cs.immunityState != LibCoreStorage.ImmunityState.LOCKDOWN,
                "IMMUNITY_LOCKDOWN"
            );
        }

        if (axs.phase11Enabled) {
            for (uint256 i; i < _cut.length; ) {
                for (
                    uint256 j;
                    j < _cut[i].functionSelectors.length;
                ) {
                    bytes4 sel =
                        _cut[i].functionSelectors[j];
                    require(
                        !axs.immortalSelectors[sel],
                        "IMMORTAL_SELECTOR"
                    );
                    unchecked { ++j; }
                }
                unchecked { ++i; }
            }
        }
    }

    // ============================================================
    // LAYER 5 — INSTITUTIONAL SECURITY
    // ============================================================

    function _runInstitutionalSecurity(
        LibCoreStorage.CoreStorage storage cs,
        FacetCut[] calldata _cut
    )
        internal
    {
	LibAurionXIStorage.AurionXIStorage storage axs = LibAurionXIStorage.aurionxiStorage();
						
        if (!axs.advancedSecurityEnabled) return;

        if (cs.immunityCheck) {
            _checkImmunity(_cut);
        }

        if (axs.singleActionRuleEnabled) {
            _singleActionOnly(_cut);
        }

        if (axs.advancedRiskCheck) {
            _checkRiskLevel();
        }

    }

    // ============================================================
    // BASE SECURITY PIPELINE
    // ============================================================

	function _runSecurityPipeline(
		LibCoreStorage.CoreStorage storage cs,
		bytes32 upgradeHash,
		bytes32 diffHash,
		FacetCut[] calldata _cut
	)
		internal
		view
	{
		// ============================================================
		// 1. BASIC STRUCTURE CHECKS (ALWAYS)
		// ============================================================

		_checkUpgradeScope(_cut, upgradeHash);

		require(!_isPhantomReplace(_cut), "PHANTOM_UPGRADE");

		_checkUpgradeRadius(_cut);

		// ============================================================
		// 2. SELECTOR SAFETY
		// ============================================================

		_checkDuplicateSelectors(_cut);
		_checkSelectorCollision(_cut);

		// required selectors (Core-driven)
		for (uint256 i; i < _cut.length; i++) {
			bytes4[] calldata selectors = _cut[i].functionSelectors;

			for (uint256 j; j < selectors.length; j++) {
				if (
					ICoreDiamond(cs.coreDiamond)
						.isSelectorRequired(selectors[j])
				) {
					// optional enforcement logic
				}
			}
		}

		// ============================================================
		// 3. FACET VALIDATION
		// ============================================================

		_checkCriticalSelectors(_cut);
		_checkFacetDependencies(_cut);

		// ============================================================
		// 4. UPGRADE GOVERNANCE (CORE-DRIVEN)
		// ============================================================

		require(
			ICoreDiamond(cs.coreDiamond)
				.isUpgradeDiffApproved(upgradeHash, diffHash),
			"UPGRADE_DIFF_NOT_APPROVED"
		);

		// ============================================================
		// 5. FINAL VALIDATION
		// ============================================================

		_validateSelectors(_cut);

		_simulateCut(_cut);
	}
    // ============================================================
    // EXECUTION
    // ============================================================
		function _executeDiamondCut(
		FacetCut[] calldata _cut,
		address _init,
		bytes calldata _calldata
	)
		internal
	{
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(!cs.upgradeExecutionLock, "UPGRADE_IN_PROGRESS");
		cs.upgradeExecutionLock = true;
		
		// ============================================================
		// EMIT EVENTS BEFORE EXECUTION
		// ============================================================

		for (uint256 i; i < _cut.length; i++) {
			address facet = _cut[i].facetAddress;
			bytes4[] calldata selectors = _cut[i].functionSelectors;

			if (_cut[i].action == FacetCutAction.Add) {
				emit FacetAdded(facet, selectors);
			} else if (_cut[i].action == FacetCutAction.Replace) {
				address oldFacet = LibDiamond.facetAddress(selectors[0]);
				emit FacetReplaced(oldFacet, facet, selectors);
			} else if (_cut[i].action == FacetCutAction.Remove) {
				for (uint256 j; j < selectors.length; j++) {
					address oldFacet = LibDiamond.facetAddress(selectors[j]);
					emit FacetSelectorRemoved(oldFacet, selectors[j]);
				}

				emit FacetRemoved(facet, selectors);
			}
		}

		// ============================================================
		// SNAPSHOT
		// ============================================================
		_takeSnapshot(_cut);
		
		// ============================================================
		// EXECUTE
		// Deprecated: do not use manual rollback.
		// EVM revert provides safe atomic rollback for diamond upgrades.	
		// ============================================================

			LibDiamond.diamondCut(
				_convertCut(_cut),
				_init,
				_calldata
			);

			bool healthy = _postUpgradeCheck();

			if (!healthy) {
				cs.upgradeExecutionLock = false;
				revert("POST_UPGRADE_CHECK_FAILED");
			}

			cs.upgradeExecutionLock = false;
		}

    // ============================================================
    // CLEANUP
    // ============================================================

		function _postExecutionCleanup(
			LibCoreStorage.CoreStorage storage cs,
			bytes32 upgradeHash,
			bool wasEmergency
		)
			internal
		{
			if (wasEmergency) {

				cs.emergencyUpgradeMode = false;
				cs.guardianApprovedEmergency = false;
				cs.emergencyApprovalCount = 0;
				cs.emergencyNonce++;
			}

			cs.lastUpgradeTime = block.timestamp;

			_resetProposal(cs, upgradeHash);

			delete cs.approvedSelectors[upgradeHash];
			delete cs.queuedUpgrades[upgradeHash];
			delete cs.upgradeExecutionTime[upgradeHash];

			emit DiamondUpgradeExecuted(upgradeHash, msg.sender );
		}
	
    // ============================================================
    // INTERNAL HELPERS
    // RESET STATE (ANTI-REPLAY)
	// ============================================================

		function _resetProposal(
			LibCoreStorage.CoreStorage storage cs, 
			bytes32 /* upgradeHash */
			) 
			internal {
		
			delete cs.pendingUpgradeHash;
			delete cs.pendingUpgradeIntentHash;
			delete cs.pendingIntent;
			delete cs.upgradeReadyTime;
			delete cs.proposalExpiryTime;
			
			cs.guardianApprovalNonce++;

		}
	

    function _hasCode(address a) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(a) }
        return size > 0;
    }

	function _isPhantomReplace(
			FacetCut[] calldata _cut
		) internal view returns (bool) {
			
			for (uint256 i; i < _cut.length; ) {
				if (_cut[i].action == FacetCutAction.Replace) {
					for (uint256 j; j < _cut[i].functionSelectors.length; ) {
						bytes4 sel = _cut[i].functionSelectors[j];
						address oldFacet =
							LibDiamond.facetAddress(sel);
						
						if (oldFacet == _cut[i].facetAddress) {
							return true;
						}
						unchecked { ++j; }
					}
				}
				unchecked { ++i; }
			}
			return false;
		}
    
	function _simulateCut(FacetCut[] calldata _cut) internal view
	{
		for (uint256 i; i < _cut.length; ) {

			for (uint256 j; j < _cut[i].functionSelectors.length; ) {
				bytes4 sel = _cut[i].functionSelectors[j];
				address current = LibDiamond.facetAddress(sel);

				if (_cut[i].action == FacetCutAction.Add) {
					require(current == address(0), "SIM_ADD_EXISTS");
				}
				if (_cut[i].action == FacetCutAction.Replace) {
					require(current != address(0), "SIM_REPLACE_MISSING");
					require(current != _cut[i].facetAddress, "SIM_SAME_REPLACE");
				}
				if (_cut[i].action == FacetCutAction.Remove) {
					require(current != address(0), "SIM_REMOVE_MISSING");
				}
				unchecked { ++j; }
			}
			unchecked { ++i; }
		}
	}

    // ============================================================
    // FUTURE DAO RULE
    // ============================================================

    function _singleActionOnly(FacetCut[] calldata _cut) internal pure {
        uint8 action = uint8(_cut[0].action);
			for (uint i = 1; i < _cut.length; i++) {
				require(uint8(_cut[i].action) == action, 
					"MIXED_ACTION_NOT_ALLOWED");
				}
			}
			
	function _isCriticalSelector(bytes4 sel) internal pure returns (bool)
		{
			return (
				sel == ITradeFacet.validateTrade.selector ||
				sel == IERC20Facet.transfer.selector ||
				sel == IERC20Facet.transferFrom.selector ||
				sel == IERC20Facet.approve.selector ||
				sel == IERC20Facet.allowance.selector ||
				sel == IERC20Facet.balanceOf.selector ||
				sel == IERC20Facet.totalSupply.selector
			);
		}
	
		function _takeSnapshot(FacetCut[] calldata _cut ) internal {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			for (uint i = 0; i < _cut.length; i++) {
				for (uint j = 0;
					 j < _cut[i].functionSelectors.length;
					 j++)
				{
					bytes4 sel = _cut[i].functionSelectors[j];
					cs.lastFacetSnapshot[sel] =
						LibDiamond.facetAddress(sel);
				}
			}
		}
		
		
		function _checkUpgradeRadius(FacetCut[] calldata _cut
		) internal pure {

			uint256 totalSelectors;
			for (uint256 i; i < _cut.length; ) {
				totalSelectors += _cut[i].functionSelectors.length;
				unchecked { ++i; }
			}
			require(
				totalSelectors <= MAX_SELECTORS_PER_UPGRADE,
				"UPGRADE_RADIUS_EXCEEDED"
			);
		}
		
		function _checkRiskLevel() internal view {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			require(cs.riskScore < 80, "RISK_TOO_HIGH");
		}
	
		function _checkImmunity(
			FacetCut[] calldata _cut
		) internal {

		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			LibAurionXIStorage.AurionXIStorage storage axs =
						LibAurionXIStorage.aurionxiStorage();

		for (uint i = 0; i < _cut.length; i++) {

			if (_cut[i].action ==
				FacetCutAction.Remove)
			{
				for (uint j = 0;
					 j < _cut[i].functionSelectors.length;
					 j++)
				{
					bytes4 sel = _cut[i].functionSelectors[j];

					if (ICoreDiamond(cs.coreDiamond).isSelectorImmutable(sel))
					{
					cs.immunityState = LibCoreStorage.ImmunityState.LOCKDOWN;
						axs.immunityLock = true;
						}
					}
				}
			}
		}

		function _validateSelectors(
			FacetCut[] calldata _cut
		) internal pure {

			for (uint256 i; i < _cut.length; ) {
				require(
					_cut[i].functionSelectors.length > 0,
					"EMPTY_SELECTOR_SET"
				);
				unchecked { ++i; }
			}
		}

		function _checkDuplicateSelectors(
			FacetCut[] calldata _cut
		) internal pure {

			uint256 total;

			for (uint256 i; i < _cut.length; i++) {
				total += _cut[i].functionSelectors.length;
			}

			bytes4[] memory seen = new bytes4[](total);
			uint256 count;

			for (uint256 i; i < _cut.length; i++) {

				bytes4[] calldata selectors = _cut[i].functionSelectors;

				for (uint256 j; j < selectors.length; j++) {

					bytes4 sel = selectors[j];
					bool exists = false;

					for (uint256 k; k < count; k++) {
						if (seen[k] == sel) {
							exists = true;
							break;
						}
					}

					require(!exists, "DUPLICATE_SELECTOR");

					seen[count] = sel;
					count++;
				}
			}
		}

		function _checkCriticalSelectors(
			FacetCut[] calldata _cut
		) internal pure {

			for(uint256 i; i < _cut.length; ){
			
				for(uint256 j; j < _cut[i].functionSelectors.length; ){
					bytes4 sel = _cut[i].functionSelectors[j];
					require(
						sel != ICoreDiamondCut.diamondCut.selector,
						"DIAMONDCUT_PROTECTED"
					);
					unchecked { ++j; }
				}
				unchecked { ++i; }
			}
		}
		
		
		function _checkSelectorCollision(FacetCut[] calldata _cut) 
			internal view 
		{
			for (uint256 i; i < _cut.length; ) {

				if (_cut[i].action != FacetCutAction.Add) {
					unchecked { ++i; }
					continue;
				}
				for (uint256 j; j < _cut[i].functionSelectors.length; ) {
					bytes4 sel = _cut[i].functionSelectors[j];

					address existingFacet = LibDiamond.facetAddress(sel);
					require(existingFacet == address(0),
						"SELECTOR_ALREADY_EXISTS"
					);
					unchecked { ++j; }
				}
				unchecked { ++i; }
			}
		}
		
		function _checkUpgradeScope(
			FacetCut[] calldata _cut,
			bytes32 upgradeHash
		) internal view {

		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			bytes4[] storage approved = cs.approvedSelectors[upgradeHash];
			require(approved.length > 0, "NO_APPROVED_SELECTORS" );

			for (uint256 i; i < _cut.length; ) {
				for (uint256 j; j < _cut[i].functionSelectors.length; ) {
					bytes4 sel = _cut[i].functionSelectors[j];

					bool allowed;
					for (uint256 k; k < approved.length; ) {
						if (approved[k] == sel) {
							allowed = true;
							break;
						}
						unchecked { ++k; }
					}
					require(allowed, "SELECTOR_NOT_APPROVED");
					unchecked { ++j; }
				}
				unchecked { ++i; }
			}
		}

		function _facetCodeHash(address facet) internal view returns (bytes32 hash)
		{
			assembly {
				hash := extcodehash(facet)
			}
		}
	
		
		function _checkFacetDependencies(
			FacetCut[] calldata _cut
		) internal view {

			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			for (uint256 i; i < _cut.length; ) {

				if (_cut[i].action == FacetCutAction.Remove) {

					bytes4[] calldata selectors = _cut[i].functionSelectors;

					for (uint256 j; j < selectors.length; ) {

						bytes4 sel = selectors[j];

						require(
							!ICoreDiamond(cs.coreDiamond).isSelectorRequired(sel),
							"REQUIRED_SELECTOR_REMOVAL"
						);

						unchecked { ++j; }
					}
				}

				unchecked { ++i; }
			}
		}
		
		function _verifyFacetIntegrity(address facet) internal view {
			LibCoreStorage.CoreStorage storage cs =
				LibCoreStorage.coreStorage();

			bytes32 codeHash;
			assembly {
				codeHash := extcodehash(facet)
			}

			// facet must be pre-approved
			require(cs.approvedFacets[facet], "FACET_NOT_WHITELISTED" );
				
				// bytecode must match approved version
			require(cs.approvedFacetCodeHash[facet] == codeHash,
				"FACET_BYTECODE_MISMATCH"
			);
			
			// facet must contain code
			require(codeHash != bytes32(0),
				"FACET_NO_CODE"
			);
		}
		
    // ============================================================
    // CONVERTER
    // ============================================================
		function _convertCut(
			FacetCut[] calldata _cut) 
			internal 
			pure
			returns (LibDiamond.FacetCut[] memory converted)
		{
			uint256 len = _cut.length;
			converted = new LibDiamond.FacetCut[](len);

			for (uint256 i; i < len; ) {
			
				FacetCut calldata c = _cut[i];
				
				converted[i] = LibDiamond.FacetCut({
					facetAddress: c.facetAddress,
					action: LibDiamond.FacetCutAction(uint8(c.action)),
					functionSelectors: c.functionSelectors
				});
				unchecked { ++i; }
			}
		}
		

		function _postUpgradeCheck()
			internal
			view
			returns (bool)
		{
			LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

			if(
				ds.selectorToFacetAndPosition[
					ICoreDiamondCut.diamondCut.selector
				].facetAddress == address(0)
			){
				return false;
			}
			if(
				ds.selectorToFacetAndPosition[
					IERC165Facet.supportsInterface.selector
				].facetAddress == address(0)
			){
				return false;
			}
			return true;
		}
		
		function _getMode(
			LibCoreStorage.CoreStorage storage cs
			) internal view returns (Mode) {
			address core = cs.coreDiamond;

		// ============================================================
		// BOOTSTRAP MODE
		// Child diamonds read bootstrap state from CoreDiamond.
		// ============================================================
		if (core != address(0)) {
			(bool bootstrapMode, uint256 until) =
				ICoreDiamond(core).getBootstrapState();

			if (bootstrapMode && block.timestamp < until) {
				return Mode.BOOTSTRAP;
			}
		}

		// ============================================================
		// CHILD EMERGENCY MODE
		// Child diamonds may enter emergency mode only when CoreDiamond
		// is the caller and CoreDiamond emergency mode is active.
		// This prevents direct external callers from using child emergency.
		// ============================================================
		if (
			core != address(0) &&
			address(this) != core &&
			msg.sender == core
		) {
			try ICoreDiamond(core).isEmergencyMode()
				returns (bool coreEmergencyMode)
			{
				if (coreEmergencyMode) {
					return Mode.EMERGENCY;
				}
			} catch {
				// If Core emergency read fails, continue to local checks.
			}
		}

		// ============================================================
		// CORE / LOCAL EMERGENCY MODE
		// Used by CoreDiamond itself.
		// ============================================================
		if (cs.emergencyUpgradeMode) {
			require(
				cs.emergencyApprovalCount >= cs.emergencyThreshold,
				"INSUFFICIENT_EMERGENCY_APPROVALS"
			);

			return Mode.EMERGENCY;
		}

		return Mode.PRODUCTION;
	}

		function _autoSyncInit(address init) internal {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			if (cs.approvedInits[init]) return;
			address core = cs.coreDiamond;

			require(
				ICoreDiamond(core).isInitApproved(init),
				"INIT_NOT_APPROVED"
			);
			cs.approvedInits[init] = true;
		}

		function _isSelectorRequired(bytes4 selector) internal view returns (bool) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			return ICoreDiamond(cs.coreDiamond).isSelectorRequired(selector);
		}

		function _computeDiffHash(FacetCut[] calldata _cut)
			internal
			view
			returns (bytes32)
		{
			bytes32 combined;

			for (uint256 i; i < _cut.length; ) {
				address newFacet = _cut[i].facetAddress;

				bytes32 newCodeHash;
				if (_cut[i].action != FacetCutAction.Remove) {
					assembly {
						newCodeHash := extcodehash(newFacet)
					}
				}

				bytes32 selectorHash;

				for (uint256 j; j < _cut[i].functionSelectors.length; ) {
					bytes4 sel = _cut[i].functionSelectors[j];
					address oldFacet = LibDiamond.facetAddress(sel);

					bytes32 oldCodeHash;
					if (oldFacet != address(0)) {
						assembly {
							oldCodeHash := extcodehash(oldFacet)
						}
					}

					selectorHash = keccak256(
						abi.encode(
							selectorHash,
							sel,
							oldFacet,
							oldCodeHash
						)
					);

					unchecked { ++j; }
				}

				combined = keccak256(
					abi.encode(
						combined,
						_cut[i].facetAddress,
						_cut[i].action,
						_cut[i].functionSelectors,
						newCodeHash,
						selectorHash
					)
				);

				unchecked { ++i; }
			}

			return combined;
		}

		
	}

 