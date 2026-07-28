// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IAnalyticsConfigFacet {
    event AnalyticsInitialized(address tokenDiamond, address tradeDiamond, address pairAddress);
    event OracleReporterUpdated(address indexed reporter);
    event ReportingPausedUpdated(bool paused);

    function initializeAnalytics(
        address tokenDiamond,
        address tradeDiamond,
        address pairAddress,
        address oracleReporter
    ) external;

    function setOracleReporter(address reporter) external;
    function setReportingPaused(bool paused) external;

    function getAnalyticsConfig()
        external
        view
        returns (
            address tokenDiamond,
            address tradeDiamond,
            address pairAddress,
            address oracleReporter,
            bool initialized,
            bool reportingPaused
        );
}