// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAnalyticsStorage } from "../../libraries/LibAnalyticsStorage.sol";
import { IWalletFlowFacet } from "../interfaces/IWalletFlowFacet.sol";

contract WalletFlowFacet is IWalletFlowFacet {
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

    function recordWalletFlow(
        address wallet,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) external override onlyReporterOrOwner {
        require(wallet != address(0), "WALLET_REQUIRED");
        require(!(isBuy && isSell), "INVALID_FLOW");

        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();
        require(s.initialized, "ANALYTICS_NOT_INITIALIZED");

        LibAnalyticsStorage.WalletFlow storage flow = s.walletFlows[wallet];

        if (!s.isTrackedWallet[wallet]) {
            s.isTrackedWallet[wallet] = true;
            s.trackedWallets.push(wallet);
        }

        if (isBuy) {
            flow.buyAmount += amount;
            flow.buyCount += 1;
        } else if (isSell) {
            flow.sellAmount += amount;
            flow.sellCount += 1;
        } else {
            flow.transferAmount += amount;
            flow.transferCount += 1;
        }

        flow.lastActivity = block.timestamp;

        emit WalletFlowRecorded(
            wallet,
            amount,
            isBuy,
            isSell,
            block.timestamp
        );
    }

    function getWalletFlow(address wallet)
        external
        view
        override
        returns (
            uint256 buyAmount,
            uint256 sellAmount,
            uint256 transferAmount,
            uint256 buyCount,
            uint256 sellCount,
            uint256 transferCount,
            uint256 lastActivity
        )
    {
        LibAnalyticsStorage.WalletFlow storage flow =
            LibAnalyticsStorage.analyticsStorage().walletFlows[wallet];

        return (
            flow.buyAmount,
            flow.sellAmount,
            flow.transferAmount,
            flow.buyCount,
            flow.sellCount,
            flow.transferCount,
            flow.lastActivity
        );
    }

    function trackedWalletCount() external view override returns (uint256) {
        return LibAnalyticsStorage.analyticsStorage().trackedWallets.length;
    }

    function trackedWalletAt(uint256 index)
        external
        view
        override
        returns (address)
    {
        return LibAnalyticsStorage.analyticsStorage().trackedWallets[index];
    }
}