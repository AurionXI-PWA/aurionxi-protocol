// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAIStorage } from "../../libraries/LibAIStorage.sol";
import { IOracleReportFacet } from "../interfaces/IOracleReportFacet.sol";

contract OracleReportFacet is IOracleReportFacet {
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

    function submitOracleReport(
        uint8 riskLevel,
        uint256 confidenceBps,
        string calldata reportType,
        string calldata summary,
        bytes32 dataHash
    ) external override onlyReporterOrOwner returns (uint256 reportId) {
        require(riskLevel <= 5, "INVALID_RISK_LEVEL");
        require(confidenceBps <= 10000, "INVALID_CONFIDENCE");

        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(s.initialized, "AI_NOT_INITIALIZED");

        reportId = ++s.reportCount;

        s.oracleReports[reportId] = LibAIStorage.OracleReport({
            timestamp: block.timestamp,
            reporter: msg.sender,
            riskLevel: riskLevel,
            confidenceBps: confidenceBps,
            reportType: reportType,
            summary: summary,
            dataHash: dataHash
        });

        emit OracleReportSubmitted(
            reportId,
            msg.sender,
            riskLevel,
            confidenceBps,
            reportType,
            summary,
            dataHash
        );
    }

    function getOracleReport(uint256 reportId)
        external
        view
        override
        returns (
            uint256 timestamp,
            address reporter,
            uint8 riskLevel,
            uint256 confidenceBps,
            string memory reportType,
            string memory summary,
            bytes32 dataHash
        )
    {
        LibAIStorage.OracleReport storage report =
            LibAIStorage.aiStorage().oracleReports[reportId];

        return (
            report.timestamp,
            report.reporter,
            report.riskLevel,
            report.confidenceBps,
            report.reportType,
            report.summary,
            report.dataHash
        );
    }

    function latestOracleReportId()
        external
        view
        override
        returns (uint256)
    {
        return LibAIStorage.aiStorage().reportCount;
    }
}