// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IAIGuardianFacet {
		event AiGuardianEnabledUpdated(bool enabled);
		event AiFirewallEnabledUpdated(bool enabled);
		event AiRiskCheckUpdated(bool enabled);

		event AiUpgradeApproved(bytes32 indexed upgradeHash);
		event AiUpgradeRevoked(bytes32 indexed upgradeHash);

		event AiFirewallApproved(bytes32 indexed upgradeHash);
		event AiFirewallRevoked(bytes32 indexed upgradeHash);

		event AiRiskScoreUpdated(uint256 riskScore);
		event AiMaxRiskUpdated(uint256 maxAllowedRisk);

		function setAiGuardianEnabled(bool enabled) external;
		function setAiFirewallEnabled(bool enabled) external;
		function setAiRiskCheck(bool enabled) external;

		function approveAiUpgrade(bytes32 upgradeHash) external;
		function revokeAiUpgrade(bytes32 upgradeHash) external;

		function approveFirewallUpgrade(bytes32 upgradeHash) external;
		function revokeFirewallUpgrade(bytes32 upgradeHash) external;

		function setAiRiskScore(uint256 riskScore) external;
		function setAiMaxAllowedRisk(uint256 maxAllowedRisk) external;

		function getAiGuardState()
			external
			view
			returns (
				bool aiGuardianEnabled,
				bool aiFirewallEnabled,
				bool aiRiskCheckEnabled,
				uint256 riskScore,
				uint256 maxAllowedRisk
			);

		function isAiUpgradeApproved(bytes32 upgradeHash)
			external
			view
			returns (bool);

		function isFirewallApproved(bytes32 upgradeHash)
			external
			view
			returns (bool);
	}