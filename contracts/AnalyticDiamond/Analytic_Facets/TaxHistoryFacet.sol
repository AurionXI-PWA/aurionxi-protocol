// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAnalyticsStorage } from "../../libraries/LibAnalyticsStorage.sol";
import { ITaxHistoryFacet } from "../interfaces/ITaxHistoryFacet.sol";

contract TaxHistoryFacet is ITaxHistoryFacet {
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

    function recordTaxSnapshot(
        uint256 buyTaxBps,
        uint256 sellTaxBps,
        uint256 panicSoftTaxBps,
        uint256 panicMediumTaxBps,
        uint256 panicHardTaxBps,
        bytes32 sourceHash,
        string calldata reason
    ) external override onlyReporterOrOwner returns (uint256 snapshotId) {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();
        require(s.initialized, "ANALYTICS_NOT_INITIALIZED");

        snapshotId = ++s.taxSnapshotCount;

        s.taxSnapshots[snapshotId] = LibAnalyticsStorage.TaxSnapshot({
            timestamp: block.timestamp,
            buyTaxBps: buyTaxBps,
            sellTaxBps: sellTaxBps,
            panicSoftTaxBps: panicSoftTaxBps,
            panicMediumTaxBps: panicMediumTaxBps,
            panicHardTaxBps: panicHardTaxBps,
            sourceHash: sourceHash,
            reason: reason
        });

        emit TaxSnapshotRecorded(
            snapshotId,
            block.timestamp,
            buyTaxBps,
            sellTaxBps,
            panicSoftTaxBps,
            panicMediumTaxBps,
            panicHardTaxBps,
            sourceHash,
            reason
        );
    }

    function getTaxSnapshot(uint256 snapshotId)
        external
        view
        override
        returns (
            uint256 timestamp,
            uint256 buyTaxBps,
            uint256 sellTaxBps,
            uint256 panicSoftTaxBps,
            uint256 panicMediumTaxBps,
            uint256 panicHardTaxBps,
            bytes32 sourceHash,
            string memory reason
        )
    {
        LibAnalyticsStorage.TaxSnapshot storage snapshot =
            LibAnalyticsStorage.analyticsStorage().taxSnapshots[snapshotId];

        return (
            snapshot.timestamp,
            snapshot.buyTaxBps,
            snapshot.sellTaxBps,
            snapshot.panicSoftTaxBps,
            snapshot.panicMediumTaxBps,
            snapshot.panicHardTaxBps,
            snapshot.sourceHash,
            snapshot.reason
        );
    }
}