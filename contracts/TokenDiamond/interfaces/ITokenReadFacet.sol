// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ITokenReadFacet {
    function getTokenInfo()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxSupply
        );

    function getTaxInfo()
        external
        view
        returns (
            uint256 buyTaxBps,
            uint256 sellTaxBps
        );

    function getWallets()
        external
        view
        returns (
            address feeCollector,
            address treasury,
            address reward,
            address liquidity,
            address marketing,
            address burn
        );

    function getStatus()
        external
        view
        returns (
            bool paused,
            bool emergencyMode,
            bool initialized,
            bool listingActive,
            uint256 listingTimestamp
        );

    function getGlobalFlags()
        external
        view
        returns (
            bool blacklistEnabled,
            uint256 limitBaseSupply
        );

    function getUserState(address user)
        external
        view
        returns (
            uint256 balance,
            bool isBlacklisted,
            bool isFeeExempt,
            bool isMarketPair,
            bool isLpPair
        );

    function getUserBasic(address user)
        external
        view
        returns (
            uint256 balance,
            bool isBlacklisted
        );

    function getGlobalState()
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxSupply,
            uint256 buyTaxBps,
            uint256 sellTaxBps,
            bool paused,
            bool emergencyMode,
            bool initialized
        );

    function getFullState(address user)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxSupply,
            uint256 buyTaxBps,
            uint256 sellTaxBps,
            bool paused,
            bool emergencyMode,
            bool initialized,
            address feeCollector,
            address treasury,
            address reward,
            address liquidity,
            address marketing,
            address burn,
            uint256 balance,
            bool isBlacklisted,
            bool isFeeExempt
        );

    function getBalances(address[] calldata users)
        external
        view
        returns (uint256[] memory balances);

    function getPairAddress()
        external
        view
        returns (address);

    function isLPPair(address pair)
        external
        view
        returns (bool);

    function getPairInfo()
        external
        view
        returns (
            address pair,
            bool lpEnabled,
            bool marketEnabled
        );
}