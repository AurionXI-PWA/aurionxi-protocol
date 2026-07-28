// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ICoreReadFacet {

    // ============================================================
    // 🔹 UPGRADE WINDOW + DAO
    // ============================================================

    function isUpgradeWindowOpen() external view returns (bool);
    function isDAOEnabled() external view returns (bool);
    function getProposalNonce() external view returns (uint256);
    function isEmergencyMode() external view returns (bool);

    // ============================================================
    // 🔹 UPGRADE STATE
    // ============================================================

    function getUpgradeState()
        external
        view
        returns (
            bytes32 pendingHash,
            bytes32 intentHash,
            uint256 readyTime,
            uint256 expiryTime
        );

    // ============================================================
    // 🔹 CORE / REGISTRY
    // ============================================================

    function getCoreDiamond() external view returns (address);
    function getDiamondCount() external view returns (uint256);

    function getAllChildDiamonds()
        external
        view
        returns (address[] memory);

    function getChildDiamond(uint256 index)
        external
        view
        returns (
            address child,
            string memory name,
            bool registered
        );

    function getChildOwner(address child)
        external
        view
        returns (address);

    function isDiamondRegistered(address child)
        external
        view
        returns (bool);

    function isRegistryLocked() external view returns (bool);

    // ============================================================
    // 🔹 GUARDIAN SYSTEM
    // ============================================================

    function isGuardian(address g) external view returns (bool);

    function getGuardianCount() external view returns (uint256);

    function isGuardianEnabled() external view returns (bool);

    function getGuardianThreshold() external view returns (uint256);

    function getEmergencyThreshold() external view returns (uint256);

    function getApprovalCount(bytes32 upgradeHash)
        external
        view
        returns (uint256);

    function hasGuardianApproved(bytes32 upgradeHash, address g)
        external
        view
        returns (bool);

    // ============================================================
    // 🔹 AI GUARDIAN
    // ============================================================

    function isAiGuardianEnabled() external view returns (bool);

    function isAiFirewallEnabled() external view returns (bool);

    function isAiRiskCheckEnabled() external view returns (bool);

    function isAiApproved(bytes32 upgradeHash) external view returns (bool);

    function getMaxAllowedRisk() external view returns (uint256);
	
	function isGuardianEmergencyApproved() external view returns (bool);
}