// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAnalyticsStorage } from "../../libraries/LibAnalyticsStorage.sol";
import { IMarketSnapshotFacet } from "../interfaces/IMarketSnapshotFacet.sol";

contract MarketSnapshotFacet is IMarketSnapshotFacet {
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

    function recordMarketSnapshot(
        uint256 arxiReserve,
        uint256 bnbReserve,
        uint256 priceE18,
        uint256 liquidityValueE18,
        bytes32 sourceHash
    ) external override onlyReporterOrOwner returns (uint256 snapshotId) {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        require(s.initialized, "ANALYTICS_NOT_INITIALIZED");

        snapshotId = ++s.marketSnapshotCount;

        s.marketSnapshots[snapshotId] = LibAnalyticsStorage.MarketSnapshot({
            timestamp: block.timestamp,
            arxiReserve: arxiReserve,
            bnbReserve: bnbReserve,
            priceE18: priceE18,
            liquidityValueE18: liquidityValueE18,
            sourceHash: sourceHash
        });

        emit MarketSnapshotRecorded(
            snapshotId,
            block.timestamp,
            arxiReserve,
            bnbReserve,
            priceE18,
            liquidityValueE18,
            sourceHash
        );
    }

    function getMarketSnapshot(uint256 snapshotId)
        external
        view
        override
        returns (
            uint256 timestamp,
            uint256 arxiReserve,
            uint256 bnbReserve,
            uint256 priceE18,
            uint256 liquidityValueE18,
            bytes32 sourceHash
        )
    {
        LibAnalyticsStorage.MarketSnapshot storage snapshot =
            LibAnalyticsStorage.analyticsStorage().marketSnapshots[snapshotId];

        return (
            snapshot.timestamp,
            snapshot.arxiReserve,
            snapshot.bnbReserve,
            snapshot.priceE18,
            snapshot.liquidityValueE18,
            snapshot.sourceHash
        );
    }

    function getLatestMarketSnapshot()
        external
        view
        override
        returns (
            uint256 snapshotId,
            uint256 timestamp,
            uint256 arxiReserve,
            uint256 bnbReserve,
            uint256 priceE18,
            uint256 liquidityValueE18,
            bytes32 sourceHash
        )
    {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        snapshotId = s.marketSnapshotCount;
        LibAnalyticsStorage.MarketSnapshot storage snapshot =
            s.marketSnapshots[snapshotId];

        return (
            snapshotId,
            snapshot.timestamp,
            snapshot.arxiReserve,
            snapshot.bnbReserve,
            snapshot.priceE18,
            snapshot.liquidityValueE18,
            snapshot.sourceHash
        );
    }
}