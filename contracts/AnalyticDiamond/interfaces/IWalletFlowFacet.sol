// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IWalletFlowFacet {
    event WalletFlowRecorded(
        address indexed wallet,
        uint256 amount,
        bool isBuy,
        bool isSell,
        uint256 timestamp
    );

    function recordWalletFlow(
        address wallet,
        uint256 amount,
        bool isBuy,
        bool isSell
    ) external;

    function getWalletFlow(address wallet)
        external
        view
        returns (
            uint256 buyAmount,
            uint256 sellAmount,
            uint256 transferAmount,
            uint256 buyCount,
            uint256 sellCount,
            uint256 transferCount,
            uint256 lastActivity
        );

    function trackedWalletCount() external view returns (uint256);
    function trackedWalletAt(uint256 index) external view returns (address);
}