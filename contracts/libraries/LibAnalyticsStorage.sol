// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

library LibAnalyticsStorage {
    bytes32 internal constant ANALYTICS_STORAGE_POSITION =
        keccak256("aurionxi.analytics.storage");

    struct MarketSnapshot {
        uint256 timestamp;
        uint256 arxiReserve;
        uint256 bnbReserve;
        uint256 priceE18;
        uint256 liquidityValueE18;
        bytes32 sourceHash;
    }

    struct WalletFlow {
        uint256 buyAmount;
        uint256 sellAmount;
        uint256 transferAmount;
        uint256 buyCount;
        uint256 sellCount;
        uint256 transferCount;
        uint256 lastActivity;
    }

    struct TaxSnapshot {
        uint256 timestamp;
        uint256 buyTaxBps;
        uint256 sellTaxBps;
        uint256 panicSoftTaxBps;
        uint256 panicMediumTaxBps;
        uint256 panicHardTaxBps;
        bytes32 sourceHash;
        string reason;
    }

    struct RiskSignal {
        uint256 timestamp;
        uint8 riskLevel;
        uint256 confidenceBps;
        string signalType;
        string summary;
        bytes32 sourceHash;
        bool reviewed;
    }

    struct AnalyticsStorage {
        address tokenDiamond;
        address tradeDiamond;
        address pairAddress;
        address oracleReporter;
        bool initialized;
        bool reportingPaused;
        uint256 latestRiskLevel;
        uint256 latestConfidenceBps;
        uint256 marketSnapshotCount;
        uint256 taxSnapshotCount;
        uint256 riskSignalCount;
        mapping(uint256 => MarketSnapshot) marketSnapshots;
        mapping(address => WalletFlow) walletFlows;
        mapping(address => bool) isTrackedWallet;
        address[] trackedWallets;
        mapping(uint256 => TaxSnapshot) taxSnapshots;
        mapping(uint256 => RiskSignal) riskSignals;
    }

    function analyticsStorage()
        internal
        pure
        returns (AnalyticsStorage storage s)
    {
        bytes32 position = ANALYTICS_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}