// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library LibAIStorage {
    bytes32 internal constant AI_STORAGE_POSITION =
        keccak256("aurionxi.ai.storage");

    enum ReviewStatus {
        Pending,
        Approved,
        Rejected,
        Executed,
        Cancelled
    }

    struct OracleReport {
        uint256 timestamp;
        address reporter;
        uint8 riskLevel;
        uint256 confidenceBps;
        string reportType;
        string summary;
        bytes32 dataHash;
    }

    struct AIRecommendation {
        uint256 timestamp;
        uint256 sourceReportId;
        uint8 riskLevel;
        uint256 confidenceBps;
        address targetDiamond;
        bytes32 actionHash;
        string recommendationType;
        string summary;
        ReviewStatus status;
    }

    struct TaxPolicySuggestion {
        uint256 timestamp;
        uint256 sourceReportId;
        uint256 currentBuyTaxBps;
        uint256 currentSellTaxBps;
        uint256 suggestedBuyTaxBps;
        uint256 suggestedSellTaxBps;
        uint256 suggestedPanicSoftTaxBps;
        uint256 suggestedPanicMediumTaxBps;
        uint256 suggestedPanicHardTaxBps;
        uint256 confidenceBps;
        string reason;
        ReviewStatus status;
    }

    struct PanicModeAdvice {
        uint256 timestamp;
        uint256 sourceReportId;
        bool shouldEnablePanicMode;
        bool shouldPauseTrading;
        uint256 suggestedDurationSeconds;
        uint8 riskLevel;
        uint256 confidenceBps;
        string reason;
        ReviewStatus status;
    }

    struct AIStorage {
        address tokenDiamond;
        address tradeDiamond;
        address analyticDiamond;
        address oracleReporter;
        bool initialized;
        bool reportingPaused;
        uint256 reportCount;
        uint256 recommendationCount;
        uint256 taxSuggestionCount;
        uint256 panicAdviceCount;
        mapping(uint256 => OracleReport) oracleReports;
        mapping(uint256 => AIRecommendation) recommendations;
        mapping(uint256 => TaxPolicySuggestion) taxSuggestions;
        mapping(uint256 => PanicModeAdvice) panicAdvices;
    }

    function aiStorage()
        internal
        pure
        returns (AIStorage storage s)
    {
        bytes32 position = AI_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}