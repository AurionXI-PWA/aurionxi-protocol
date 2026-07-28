// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IAIRecommendationFacet {
    event AIRecommendationCreated(
        uint256 indexed recommendationId,
        uint256 indexed sourceReportId,
        uint8 riskLevel,
        uint256 confidenceBps,
        address targetDiamond,
        bytes32 actionHash,
        string recommendationType,
        string summary
    );

    event AIRecommendationStatusUpdated(uint256 indexed recommendationId, uint8 status);

    function createRecommendation(
        uint256 sourceReportId,
        uint8 riskLevel,
        uint256 confidenceBps,
        address targetDiamond,
        bytes32 actionHash,
        string calldata recommendationType,
        string calldata summary
    ) external returns (uint256 recommendationId);

    function approveRecommendation(uint256 recommendationId) external;
    function rejectRecommendation(uint256 recommendationId) external;
    function markRecommendationExecuted(uint256 recommendationId) external;
    function cancelRecommendation(uint256 recommendationId) external;

    function getRecommendation(uint256 recommendationId)
        external
        view
        returns (
            uint256 timestamp,
            uint256 sourceReportId,
            uint8 riskLevel,
            uint256 confidenceBps,
            address targetDiamond,
            bytes32 actionHash,
            string memory recommendationType,
            string memory summary,
            uint8 status
        );
}