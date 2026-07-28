// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IMarketSnapshotFacet {
    event MarketSnapshotRecorded(
        uint256 indexed snapshotId,
        uint256 timestamp,
        uint256 arxiReserve,
        uint256 bnbReserve,
        uint256 priceE18,
        uint256 liquidityValueE18,
        bytes32 sourceHash
    );

    function recordMarketSnapshot(
        uint256 arxiReserve,
        uint256 bnbReserve,
        uint256 priceE18,
        uint256 liquidityValueE18,
        bytes32 sourceHash
    ) external returns (uint256 snapshotId);

    function getMarketSnapshot(uint256 snapshotId)
        external
        view
        returns (
            uint256 timestamp,
            uint256 arxiReserve,
            uint256 bnbReserve,
            uint256 priceE18,
            uint256 liquidityValueE18,
            bytes32 sourceHash
        );

    function getLatestMarketSnapshot()
        external
        view
        returns (
            uint256 snapshotId,
            uint256 timestamp,
            uint256 arxiReserve,
            uint256 bnbReserve,
            uint256 priceE18,
            uint256 liquidityValueE18,
            bytes32 sourceHash
        );
}