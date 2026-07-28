// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ITaxHistoryFacet {
    event TaxSnapshotRecorded(
        uint256 indexed snapshotId,
        uint256 timestamp,
        uint256 buyTaxBps,
        uint256 sellTaxBps,
        uint256 panicSoftTaxBps,
        uint256 panicMediumTaxBps,
        uint256 panicHardTaxBps,
        bytes32 sourceHash,
        string reason
    );

    function recordTaxSnapshot(
        uint256 buyTaxBps,
        uint256 sellTaxBps,
        uint256 panicSoftTaxBps,
        uint256 panicMediumTaxBps,
        uint256 panicHardTaxBps,
        bytes32 sourceHash,
        string calldata reason
    ) external returns (uint256 snapshotId);

    function getTaxSnapshot(uint256 snapshotId)
        external
        view
        returns (
            uint256 timestamp,
            uint256 buyTaxBps,
            uint256 sellTaxBps,
            uint256 panicSoftTaxBps,
            uint256 panicMediumTaxBps,
            uint256 panicHardTaxBps,
            bytes32 sourceHash,
            string memory reason
        );
}