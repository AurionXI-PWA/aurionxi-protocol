// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IRewardFacet
 * @notice Interface for RewardFacet — Incentive & Activity Tracking
 * @dev Declares events and external functions for reward distribution and activity tracking
 */
interface IRewardFacet {
    // =============================================================
    //                          EVENTS
    // =============================================================
    event RewardDistributorUpdated(address indexed distributor);
    event RewardAssigned(address indexed user, uint256 amount);
    event RewardDistributed(address indexed user, uint256 amount, uint256 timestamp);
    event RewardPointsSynced(address indexed user, uint256 oldPoints, uint256 newPoints);
    event EcosystemNotified(address indexed user, uint256 amount, string module);
	event ModuleAdded(string name, address module);

    // =============================================================
    //                          FUNCTIONS
    // =============================================================

    /// @notice Set the reward distributor contract
    function setRewardDistributor(address distributor) external;

    /// @notice Register a company or ecosystem module for notifications
    function registerModule(string memory name, address module) external;

    /// @notice Called internally whenever token activity happens
    function onTokenActivity(address user, uint256 amount) external;

    /// @notice Calculate and distribute rewards based on token activity
    function distributeReward(address user) external;

    /// @notice Distribute rewards for multiple users in one transaction
    function batchDistribute(address[] calldata users) external;

    /// @notice Get accumulated activity points for a user
    function getUserPoints(address user) external view returns (uint256);

    /// @notice Get the current reward distributor contract address
    function getRewardDistributor() external view returns (address);

    /// @notice Get a registered ecosystem module by name
    function getRegisteredModule(string memory name) external view returns (address);
}