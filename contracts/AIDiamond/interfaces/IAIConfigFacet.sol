// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IAIConfigFacet {
    event AIInitialized(
        address tokenDiamond,
        address tradeDiamond,
        address analyticDiamond,
        address oracleReporter
    );
    event AIOracleReporterUpdated(address indexed reporter);
    event AIReportingPausedUpdated(bool paused);

    function initializeAI(
        address tokenDiamond,
        address tradeDiamond,
        address analyticDiamond,
        address oracleReporter
    ) external;

    function setAIOracleReporter(address reporter) external;
    function setAIReportingPaused(bool paused) external;

    function getAIConfig()
        external
        view
        returns (
            address tokenDiamond,
            address tradeDiamond,
            address analyticDiamond,
            address oracleReporter,
            bool initialized,
            bool reportingPaused
        );
}