// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IGuardianFacet {

	event SecurityFlagUpdated(string flagName, bool status);
	event GuardianThresholdUpdated(uint256 threshold);
	event CooldownUpdated(uint256 hoursDelay);
    event GuardianApproved(address indexed guardian, bytes32 indexed upgradeHash);

		function addGuardian(address g) external;
		function removeGuardian(address g) external;

		function setGuardianThreshold(uint256 threshold) external;
		function setEmergencyThreshold(uint256 t) external;
		function approveUpgrade(bytes32 upgradeHash) external;
			
		function revokeApproval(bytes32 upgradeHash) external;
		function approveEmergency() external;
		
		function enableAdvancedSecurity(bool status) external;
		function enableAIGuardian(bool status) external;
		
		function setUpgradeCooldown(uint256 hoursDelay) external;
		function setGuardianEnabled(bool enabled) external;
		function resetEmergencyApprovals() external;
	
	
	}