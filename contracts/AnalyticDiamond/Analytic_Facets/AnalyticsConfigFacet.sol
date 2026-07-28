// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAnalyticsStorage } from "../../libraries/LibAnalyticsStorage.sol";
import { IAnalyticsConfigFacet } from "../interfaces/IAnalyticsConfigFacet.sol";

contract AnalyticsConfigFacet is IAnalyticsConfigFacet {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function initializeAnalytics(
        address tokenDiamond,
        address tradeDiamond,
        address pairAddress,
        address oracleReporter
    ) external override onlyOwner {
        require(tokenDiamond != address(0), "TOKEN_REQUIRED");
        require(pairAddress != address(0), "PAIR_REQUIRED");

        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        require(!s.initialized, "ANALYTICS_ALREADY_INITIALIZED");

        s.tokenDiamond = tokenDiamond;
        s.tradeDiamond = tradeDiamond;
        s.pairAddress = pairAddress;
        s.oracleReporter = oracleReporter;
        s.initialized = true;

        emit AnalyticsInitialized(tokenDiamond, tradeDiamond, pairAddress);
        emit OracleReporterUpdated(oracleReporter);
    }

    function setOracleReporter(address reporter)
        external
        override
        onlyOwner
    {
        LibAnalyticsStorage.analyticsStorage().oracleReporter = reporter;
        emit OracleReporterUpdated(reporter);
    }

    function setReportingPaused(bool paused)
        external
        override
        onlyOwner
    {
        LibAnalyticsStorage.analyticsStorage().reportingPaused = paused;
        emit ReportingPausedUpdated(paused);
    }

    function getAnalyticsConfig()
        external
        view
        override
        returns (
            address tokenDiamond,
            address tradeDiamond,
            address pairAddress,
            address oracleReporter,
            bool initialized,
            bool reportingPaused
        )
    {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        return (
            s.tokenDiamond,
            s.tradeDiamond,
            s.pairAddress,
            s.oracleReporter,
            s.initialized,
            s.reportingPaused
        );
    }
}