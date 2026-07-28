// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ITaxPolicySuggestionFacet {
    event TaxPolicySuggested(
        uint256 indexed suggestionId,
        uint256 indexed sourceReportId,
        uint256 currentBuyTaxBps,
        uint256 currentSellTaxBps,
        uint256 suggestedBuyTaxBps,
        uint256 suggestedSellTaxBps,
        uint256 suggestedPanicSoftTaxBps,
        uint256 suggestedPanicMediumTaxBps,
        uint256 suggestedPanicHardTaxBps,
        uint256 confidenceBps,
        string reason
    );

    event TaxPolicySuggestionStatusUpdated(uint256 indexed suggestionId, uint8 status);

    function suggestTaxPolicy(
        uint256 sourceReportId,
        uint256 currentBuyTaxBps,
        uint256 currentSellTaxBps,
        uint256 suggestedBuyTaxBps,
        uint256 suggestedSellTaxBps,
        uint256 suggestedPanicSoftTaxBps,
        uint256 suggestedPanicMediumTaxBps,
        uint256 suggestedPanicHardTaxBps,
        uint256 confidenceBps,
        string calldata reason
    ) external returns (uint256 suggestionId);

    function approveTaxSuggestion(uint256 suggestionId) external;
    function rejectTaxSuggestion(uint256 suggestionId) external;
    function markTaxSuggestionExecuted(uint256 suggestionId) external;
    function cancelTaxSuggestion(uint256 suggestionId) external;

    function getTaxSuggestion(uint256 suggestionId)
        external
        view
        returns (
            uint256 timestamp,
            uint256 sourceReportId,
            uint256 currentBuyTaxBps,
            uint256 currentSellTaxBps,
            uint256 suggestedBuyTaxBps,
            uint256 suggestedSellTaxBps,
            uint256 suggestedPanicSoftTaxBps,
            uint256 suggestedPanicMediumTaxBps,
            uint256 suggestedPanicHardTaxBps,
            uint256 confidenceBps,
            string memory reason,
            uint8 status
        );
}