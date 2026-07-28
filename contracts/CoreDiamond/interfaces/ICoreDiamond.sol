// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ICoreDiamondCut } from "./ICoreDiamondCut.sol";
import { ISecurityFacet } from "../interfaces/ISecurityFacet.sol";
import { IBatchExecutor } from "../interfaces/IBatchExecutor.sol";

	// @title ICoreDiamond
	
	// @notice Centralized interface for CoreDiamond, 
	
	interface ICoreDiamond is ISecurityFacet {
	
    	
	// DiamondCut execution (EIP-2535 standard)
		function diamondCut(
			ICoreDiamondCut.FacetCut[] calldata cut,
			address init,
			bytes calldata data
		) external;
		
		function isChildUpgradeReady(
			address child,
			bytes32 upgradeHash,
			bytes32 diffHash
		) external view returns (bool);
	
		function isEmergencyMode() external view returns (bool);
		
	}