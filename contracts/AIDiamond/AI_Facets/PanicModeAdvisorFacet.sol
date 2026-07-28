// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAIStorage } from "../../libraries/LibAIStorage.sol";
import { IPanicModeAdvisorFacet } from "../interfaces/IPanicModeAdvisorFacet.sol";

contract PanicModeAdvisorFacet is IPanicModeAdvisorFacet {
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

    function createPanicModeAdvice(
        uint256 sourceReportId,
        bool shouldEnablePanicMode,
        bool shouldPauseTrading,
        uint256 suggestedDurationSeconds,
        uint8 riskLevel,
        uint256 confidenceBps,
        string calldata reason
    ) external override onlyReporterOrOwner returns (uint256 adviceId) {
        require(riskLevel <= 5, "INVALID_RISK_LEVEL");
        require(confidenceBps <= 10000, "INVALID_CONFIDENCE");

        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(s.initialized, "AI_NOT_INITIALIZED");

        adviceId = ++s.panicAdviceCount;

        s.panicAdvices[adviceId] = LibAIStorage.PanicModeAdvice({
            timestamp: block.timestamp,
            sourceReportId: sourceReportId,
            shouldEnablePanicMode: shouldEnablePanicMode,
            shouldPauseTrading: shouldPauseTrading,
            suggestedDurationSeconds: suggestedDurationSeconds,
            riskLevel: riskLevel,
            confidenceBps: confidenceBps,
            reason: reason,
            status: LibAIStorage.ReviewStatus.Pending
        });

        emit PanicModeAdviceCreated(
            adviceId,
            sourceReportId,
            shouldEnablePanicMode,
            shouldPauseTrading,
            suggestedDurationSeconds,
            riskLevel,
            confidenceBps,
            reason
        );
    }

    function approvePanicAdvice(uint256 adviceId)
        external
        override
        onlyOwner
    {
        _setPanicAdviceStatus(adviceId, LibAIStorage.ReviewStatus.Approved);
    }

    function rejectPanicAdvice(uint256 adviceId)
        external
        override
        onlyOwner
    {
        _setPanicAdviceStatus(adviceId, LibAIStorage.ReviewStatus.Rejected);
    }

    function markPanicAdviceExecuted(uint256 adviceId)
        external
        override
        onlyOwner
    {
        _setPanicAdviceStatus(adviceId, LibAIStorage.ReviewStatus.Executed);
    }

    function cancelPanicAdvice(uint256 adviceId)
        external
        override
        onlyOwner
    {
        _setPanicAdviceStatus(adviceId, LibAIStorage.ReviewStatus.Cancelled);
    }

    function getPanicAdvice(uint256 adviceId)
        external
        view
        override
        returns (
            uint256 timestamp,
            uint256 sourceReportId,
            bool shouldEnablePanicMode,
            bool shouldPauseTrading,
            uint256 suggestedDurationSeconds,
            uint8 riskLevel,
            uint256 confidenceBps,
            string memory reason,
            uint8 status
        )
    {
        LibAIStorage.PanicModeAdvice storage advice =
            LibAIStorage.aiStorage().panicAdvices[adviceId];

        return (
            advice.timestamp,
            advice.sourceReportId,
            advice.shouldEnablePanicMode,
            advice.shouldPauseTrading,
            advice.suggestedDurationSeconds,
            advice.riskLevel,
            advice.confidenceBps,
            advice.reason,
            uint8(advice.status)
        );
    }

    function _setPanicAdviceStatus(
        uint256 adviceId,
        LibAIStorage.ReviewStatus status
    ) internal {
        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(
            adviceId > 0 &&
                adviceId <= s.panicAdviceCount,
            "INVALID_PANIC_ADVICE"
        );

        s.panicAdvices[adviceId].status = status;
        emit PanicModeAdviceStatusUpdated(adviceId, uint8(status));
    }
}