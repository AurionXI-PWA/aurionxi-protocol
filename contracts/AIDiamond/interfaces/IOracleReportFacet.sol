// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IOracleReportFacet {
    event OracleReportSubmitted(
        uint256 indexed reportId,
        address indexed reporter,
        uint8 riskLevel,
        uint256 confidenceBps,
        string reportType,
        string summary,
        bytes32 dataHash
    );

    function submitOracleReport(
        uint8 riskLevel,
        uint256 confidenceBps,
        string calldata reportType,
        string calldata summary,
        bytes32 dataHash
    ) external returns (uint256 reportId);

    function getOracleReport(uint256 reportId)
        external
        view
        returns (
            uint256 timestamp,
            address reporter,
            uint8 riskLevel,
            uint256 confidenceBps,
            string memory reportType,
            string memory summary,
            bytes32 dataHash
        );

    function latestOracleReportId() external view returns (uint256);
}