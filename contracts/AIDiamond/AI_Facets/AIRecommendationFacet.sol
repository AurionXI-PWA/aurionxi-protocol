// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAIStorage } from "../../libraries/LibAIStorage.sol";
import { IAIRecommendationFacet } from "../interfaces/IAIRecommendationFacet.sol";

contract AIRecommendationFacet is IAIRecommendationFacet {
    modifier onlyReporterOrOwner() {
        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();

        require(!s.reportingPaused, "AI_REPORTING_PAUSED");
        require(
            msg.sender == s.oracleReporter ||
                msg.sender == LibDiamond.contractOwner(),
            "NOT_AI_REPORTER"
        );
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function createRecommendation(
        uint256 sourceReportId,
        uint8 riskLevel,
        uint256 confidenceBps,
        address targetDiamond,
        bytes32 actionHash,
        string calldata recommendationType,
        string calldata summary
    ) external override onlyReporterOrOwner returns (uint256 recommendationId) {
        require(riskLevel <= 5, "INVALID_RISK_LEVEL");
        require(confidenceBps <= 10000, "INVALID_CONFIDENCE");
        require(targetDiamond != address(0), "TARGET_REQUIRED");

        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(s.initialized, "AI_NOT_INITIALIZED");

        recommendationId = ++s.recommendationCount;

        s.recommendations[recommendationId] = LibAIStorage.AIRecommendation({
            timestamp: block.timestamp,
            sourceReportId: sourceReportId,
            riskLevel: riskLevel,
            confidenceBps: confidenceBps,
            targetDiamond: targetDiamond,
            actionHash: actionHash,
            recommendationType: recommendationType,
            summary: summary,
            status: LibAIStorage.ReviewStatus.Pending
        });

        emit AIRecommendationCreated(
            recommendationId,
            sourceReportId,
            riskLevel,
            confidenceBps,
            targetDiamond,
            actionHash,
            recommendationType,
            summary
        );
    }

    function approveRecommendation(uint256 recommendationId)
        external
        override
        onlyOwner
    {
        _setStatus(recommendationId, LibAIStorage.ReviewStatus.Approved);
    }

    function rejectRecommendation(uint256 recommendationId)
        external
        override
        onlyOwner
    {
        _setStatus(recommendationId, LibAIStorage.ReviewStatus.Rejected);
    }

    function markRecommendationExecuted(uint256 recommendationId)
        external
        override
        onlyOwner
    {
        _setStatus(recommendationId, LibAIStorage.ReviewStatus.Executed);
    }

    function cancelRecommendation(uint256 recommendationId)
        external
        override
        onlyOwner
    {
        _setStatus(recommendationId, LibAIStorage.ReviewStatus.Cancelled);
    }

    function getRecommendation(uint256 recommendationId)
        external
        view
        override
        returns (
            uint256 timestamp,
            uint256 sourceReportId,
            uint8 riskLevel,
            uint256 confidenceBps,
            address targetDiamond,
            bytes32 actionHash,
            string memory recommendationType,
            string memory summary,
            uint8 status
        )
    {
        LibAIStorage.AIRecommendation storage rec =
            LibAIStorage.aiStorage().recommendations[recommendationId];

        return (
            rec.timestamp,
            rec.sourceReportId,
            rec.riskLevel,
            rec.confidenceBps,
            rec.targetDiamond,
            rec.actionHash,
            rec.recommendationType,
            rec.summary,
            uint8(rec.status)
        );
    }

    function _setStatus(
        uint256 recommendationId,
        LibAIStorage.ReviewStatus status
    ) internal {
        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(
            recommendationId > 0 &&
                recommendationId <= s.recommendationCount,
            "INVALID_RECOMMENDATION"
        );

        s.recommendations[recommendationId].status = status;
        emit AIRecommendationStatusUpdated(recommendationId, uint8(status));
    }
}