// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IPanicModeAdvisorFacet {
    event PanicModeAdviceCreated(
        uint256 indexed adviceId,
        uint256 indexed sourceReportId,
        bool shouldEnablePanicMode,
        bool shouldPauseTrading,
        uint256 suggestedDurationSeconds,
        uint8 riskLevel,
        uint256 confidenceBps,
        string reason
    );

    event PanicModeAdviceStatusUpdated(uint256 indexed adviceId, uint8 status);

    function createPanicModeAdvice(
        uint256 sourceReportId,
        bool shouldEnablePanicMode,
        bool shouldPauseTrading,
        uint256 suggestedDurationSeconds,
        uint8 riskLevel,
        uint256 confidenceBps,
        string calldata reason
    ) external returns (uint256 adviceId);

    function approvePanicAdvice(uint256 adviceId) external;
    function rejectPanicAdvice(uint256 adviceId) external;
    function markPanicAdviceExecuted(uint256 adviceId) external;
    function cancelPanicAdvice(uint256 adviceId) external;

    function getPanicAdvice(uint256 adviceId)
        external
        view
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
        );
}