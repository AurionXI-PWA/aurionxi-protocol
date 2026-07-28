// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";
import { IAIGuardianFacet } from "../interfaces/IAIGuardianFacet.sol";

contract AIGuardianFacet is IAIGuardianFacet {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

		function setAiGuardianEnabled(bool enabled) external onlyOwner {
			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.aiGuardianEnabled = enabled;

			emit AiGuardianEnabledUpdated(enabled);
		}

		function setAiFirewallEnabled(bool enabled) external onlyOwner {
			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.aiFirewallEnabled = enabled;

			emit AiFirewallEnabledUpdated(enabled);
		}

		function setAiRiskCheck(bool enabled) external onlyOwner {
			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.aiRiskCheckEnabled = enabled;

			emit AiRiskCheckUpdated(enabled);
		}

		function approveAiUpgrade(bytes32 upgradeHash) external onlyOwner {
			require(upgradeHash != bytes32(0), "INVALID_HASH");

			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.aiApproved[upgradeHash] = true;
			axs.aiApprovedHash = upgradeHash;

			emit AiUpgradeApproved(upgradeHash);
		}

		function revokeAiUpgrade(bytes32 upgradeHash) external onlyOwner {
			require(upgradeHash != bytes32(0), "INVALID_HASH");

			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.aiApproved[upgradeHash] = false;

			if (axs.aiApprovedHash == upgradeHash) {
				delete axs.aiApprovedHash;
			}

			emit AiUpgradeRevoked(upgradeHash);
		}

		function approveFirewallUpgrade(bytes32 upgradeHash) external onlyOwner {
			require(upgradeHash != bytes32(0), "INVALID_HASH");

			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.firewallApproved[upgradeHash] = true;

			emit AiFirewallApproved(upgradeHash);
		}

		function revokeFirewallUpgrade(bytes32 upgradeHash) external onlyOwner {
			require(upgradeHash != bytes32(0), "INVALID_HASH");

			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.firewallApproved[upgradeHash] = false;

			emit AiFirewallRevoked(upgradeHash);
		}

		function setAiRiskScore(uint256 riskScore) external onlyOwner {
			require(riskScore <= 100, "INVALID_RISK_SCORE");

			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.riskScore = riskScore;

			emit AiRiskScoreUpdated(riskScore);
		}

		function setAiMaxAllowedRisk(uint256 maxAllowedRisk) external onlyOwner {
			require(maxAllowedRisk <= 100, "INVALID_MAX_RISK");

			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			axs.maxAllowedRisk = maxAllowedRisk;

			emit AiMaxRiskUpdated(maxAllowedRisk);
		}

		function getAiGuardState()
			external
			view
			returns (
				bool aiGuardianEnabled,
				bool aiFirewallEnabled,
				bool aiRiskCheckEnabled,
				uint256 riskScore,
				uint256 maxAllowedRisk
			)
		{
			LibAurionXIStorage.AurionXIStorage storage axs =
				LibAurionXIStorage.aurionxiStorage();

			return (
				axs.aiGuardianEnabled,
				axs.aiFirewallEnabled,
				axs.aiRiskCheckEnabled,
				axs.riskScore,
				axs.maxAllowedRisk
			);
		}

		function isAiUpgradeApproved(bytes32 upgradeHash)
			external
			view
			returns (bool)
		{
			return LibAurionXIStorage.aurionxiStorage().aiApproved[upgradeHash];
		}

		function isFirewallApproved(bytes32 upgradeHash)
			external
			view
			returns (bool)
		{
			return LibAurionXIStorage.aurionxiStorage().firewallApproved[upgradeHash];
		}
	}