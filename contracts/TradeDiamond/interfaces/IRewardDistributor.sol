// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/// @title IRewardDistributor
/// @notice Interface for reward distribution contracts
interface IRewardDistributor {
    /// @notice Distribute rewards to a user
    /// @param recipient The address of the user receiving rewards
    /// @param amount The amount of reward tokens to distribute
    function distribute(address recipient, uint256 amount) external;

    /// @notice Emitted when rewards are distributed
    /// @param recipient The address of the user receiving rewards
    /// @param amount The amount of reward tokens distributed
    /// @param timestamp The time of distribution
    event RewardDistributed(address indexed recipient, uint256 amount, uint256 timestamp);
}