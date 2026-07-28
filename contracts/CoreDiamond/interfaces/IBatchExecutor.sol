// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ICoreDiamondCut } from "../interfaces/ICoreDiamondCut.sol";

interface IBatchExecutor
	{
		 struct Call {
			address target;
			uint256 value;
			bytes data;
		}
		
		// ============================================================
    // EVENTS
    // ============================================================
	event ChildCallExecuted(address indexed child, uint256 index, address target, bytes data);
    event ChildDiamondCutExecuted(address indexed child, uint256 indexed index,
										address init, bytes data );
	
	event ChildUpgradeScheduled(bytes32 upgradeHash, uint256 readyTime);
	event ChildScheduledUpgradeExecuted(bytes32 upgradeHash, address child);
	event BatchExecuted(uint256 count);
	event ChildUpgradeStateReset(bytes32 indexed upgradeHash);
	
	function cutChildDiamondFacet(
        uint256 index,
        ICoreDiamondCut.FacetCut[] calldata cut,
        address init,
        bytes calldata data
    )
        external;
	
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
		) external;
		
		function executeChildScheduledUpgrade(
			uint256 index,
			ICoreDiamondCut.FacetCut[] calldata cut,
			address init,
			bytes calldata data
		) external;
		
		function childDiamondAt(uint256 index) external view returns (address);
		function executeBatch(Call[] calldata calls) external;
		
		function isChildUpgradeReady(
			address child,
			bytes32 upgradeHash,
			bytes32 diffHash
		) external view returns (bool);

		function resetChildUpgradeState(bytes32 upgradeHash) external;
	}