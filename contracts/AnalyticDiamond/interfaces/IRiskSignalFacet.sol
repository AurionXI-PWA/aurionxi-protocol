// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IRiskSignalFacet {
    event RiskSignalRecorded(
        uint256 indexed signalId,
        uint8 riskLevel,
        uint256 confidenceBps,
        string signalType,
        string summary,
        bytes32 sourceHash
    );

    event RiskSignalReviewed(uint256 indexed signalId);

    function recordRiskSignal(
        uint8 riskLevel,
        uint256 confidenceBps,
        string calldata signalType,
        string calldata summary,
        bytes32 sourceHash
    ) external returns (uint256 signalId);

    function markRiskSignalReviewed(uint256 signalId) external;

    function getRiskSignal(uint256 signalId)
        external
        view
        returns (
            uint256 timestamp,
            uint8 riskLevel,
            uint256 confidenceBps,
            string memory signalType,
            string memory summary,
            bytes32 sourceHash,
            bool reviewed
        );

    function getLatestRisk()
        external
        view
        returns (uint256 riskLevel, uint256 confidenceBps);
}