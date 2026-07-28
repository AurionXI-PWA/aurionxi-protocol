// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAIStorage } from "../../libraries/LibAIStorage.sol";
import { ITaxPolicySuggestionFacet } from "../interfaces/ITaxPolicySuggestionFacet.sol";

contract TaxPolicySuggestionFacet is ITaxPolicySuggestionFacet {
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
    ) external override onlyReporterOrOwner returns (uint256 suggestionId) {
        require(confidenceBps <= 10000, "INVALID_CONFIDENCE");
        require(suggestedBuyTaxBps <= 10000, "BUY_TAX_TOO_HIGH");
        require(suggestedSellTaxBps <= 10000, "SELL_TAX_TOO_HIGH");
        require(suggestedPanicSoftTaxBps <= 10000, "SOFT_TAX_TOO_HIGH");
        require(suggestedPanicMediumTaxBps <= 10000, "MEDIUM_TAX_TOO_HIGH");
        require(suggestedPanicHardTaxBps <= 10000, "HARD_TAX_TOO_HIGH");

        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(s.initialized, "AI_NOT_INITIALIZED");

        suggestionId = ++s.taxSuggestionCount;

        s.taxSuggestions[suggestionId] = LibAIStorage.TaxPolicySuggestion({
            timestamp: block.timestamp,
            sourceReportId: sourceReportId,
            currentBuyTaxBps: currentBuyTaxBps,
            currentSellTaxBps: currentSellTaxBps,
            suggestedBuyTaxBps: suggestedBuyTaxBps,
            suggestedSellTaxBps: suggestedSellTaxBps,
            suggestedPanicSoftTaxBps: suggestedPanicSoftTaxBps,
            suggestedPanicMediumTaxBps: suggestedPanicMediumTaxBps,
            suggestedPanicHardTaxBps: suggestedPanicHardTaxBps,
            confidenceBps: confidenceBps,
            reason: reason,
            status: LibAIStorage.ReviewStatus.Pending
        });

        emit TaxPolicySuggested(
            suggestionId,
            sourceReportId,
            currentBuyTaxBps,
            currentSellTaxBps,
            suggestedBuyTaxBps,
            suggestedSellTaxBps,
            suggestedPanicSoftTaxBps,
            suggestedPanicMediumTaxBps,
            suggestedPanicHardTaxBps,
            confidenceBps,
            reason
        );
    }

    function approveTaxSuggestion(uint256 suggestionId)
        external
        override
        onlyOwner
    {
        _setTaxSuggestionStatus(suggestionId, LibAIStorage.ReviewStatus.Approved);
    }

    function rejectTaxSuggestion(uint256 suggestionId)
        external
        override
        onlyOwner
    {
        _setTaxSuggestionStatus(suggestionId, LibAIStorage.ReviewStatus.Rejected);
    }

    function markTaxSuggestionExecuted(uint256 suggestionId)
        external
        override
        onlyOwner
    {
        _setTaxSuggestionStatus(suggestionId, LibAIStorage.ReviewStatus.Executed);
    }

    function cancelTaxSuggestion(uint256 suggestionId)
        external
        override
        onlyOwner
    {
        _setTaxSuggestionStatus(suggestionId, LibAIStorage.ReviewStatus.Cancelled);
    }

    function getTaxSuggestion(uint256 suggestionId)
        external
        view
        override
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
        )
    {
        LibAIStorage.TaxPolicySuggestion storage suggestion =
            LibAIStorage.aiStorage().taxSuggestions[suggestionId];

        return (
            suggestion.timestamp,
            suggestion.sourceReportId,
            suggestion.currentBuyTaxBps,
            suggestion.currentSellTaxBps,
            suggestion.suggestedBuyTaxBps,
            suggestion.suggestedSellTaxBps,
            suggestion.suggestedPanicSoftTaxBps,
            suggestion.suggestedPanicMediumTaxBps,
            suggestion.suggestedPanicHardTaxBps,
            suggestion.confidenceBps,
            suggestion.reason,
            uint8(suggestion.status)
        );
    }

    function _setTaxSuggestionStatus(
        uint256 suggestionId,
        LibAIStorage.ReviewStatus status
    ) internal {
        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(
            suggestionId > 0 &&
                suggestionId <= s.taxSuggestionCount,
            "INVALID_TAX_SUGGESTION"
        );

        s.taxSuggestions[suggestionId].status = status;
        emit TaxPolicySuggestionStatusUpdated(suggestionId, uint8(status));
    }
}