// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAnalyticsStorage } from "../../libraries/LibAnalyticsStorage.sol";
import { IRiskSignalFacet } from "../interfaces/IRiskSignalFacet.sol";

contract RiskSignalFacet is IRiskSignalFacet {
    modifier onlyReporterOrOwner() {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        require(!s.reportingPaused, "REPORTING_PAUSED");
        require(
            msg.sender == s.oracleReporter ||
                msg.sender == LibDiamond.contractOwner(),
            "NOT_REPORTER"
        );
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function recordRiskSignal(
        uint8 riskLevel,
        uint256 confidenceBps,
        string calldata signalType,
        string calldata summary,
        bytes32 sourceHash
    ) external override onlyReporterOrOwner returns (uint256 signalId) {
        require(riskLevel <= 5, "INVALID_RISK_LEVEL");
        require(confidenceBps <= 10000, "INVALID_CONFIDENCE");

        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();
        require(s.initialized, "ANALYTICS_NOT_INITIALIZED");

        signalId = ++s.riskSignalCount;

        s.riskSignals[signalId] = LibAnalyticsStorage.RiskSignal({
            timestamp: block.timestamp,
            riskLevel: riskLevel,
            confidenceBps: confidenceBps,
            signalType: signalType,
            summary: summary,
            sourceHash: sourceHash,
            reviewed: false
        });

        s.latestRiskLevel = riskLevel;
        s.latestConfidenceBps = confidenceBps;

        emit RiskSignalRecorded(
            signalId,
            riskLevel,
            confidenceBps,
            signalType,
            summary,
            sourceHash
        );
    }

    function markRiskSignalReviewed(uint256 signalId)
        external
        override
        onlyOwner
    {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();
        require(signalId > 0 && signalId <= s.riskSignalCount, "INVALID_SIGNAL");

        s.riskSignals[signalId].reviewed = true;
        emit RiskSignalReviewed(signalId);
    }

    function getRiskSignal(uint256 signalId)
        external
        view
        override
        returns (
            uint256 timestamp,
            uint8 riskLevel,
            uint256 confidenceBps,
            string memory signalType,
            string memory summary,
            bytes32 sourceHash,
            bool reviewed
        )
    {
        LibAnalyticsStorage.RiskSignal storage signal =
            LibAnalyticsStorage.analyticsStorage().riskSignals[signalId];

        return (
            signal.timestamp,
            signal.riskLevel,
            signal.confidenceBps,
            signal.signalType,
            signal.summary,
            signal.sourceHash,
            signal.reviewed
        );
    }

    function getLatestRisk()
        external
        view
        override
        returns (uint256 riskLevel, uint256 confidenceBps)
    {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        return (s.latestRiskLevel, s.latestConfidenceBps);
    }
}