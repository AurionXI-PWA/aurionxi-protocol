// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {LibAnalyticsStorage
} from "../../libraries/LibAnalyticsStorage.sol";

import {ITokenReadExternal
} from "../interfaces/ITokenReadExternal.sol";

import {ITradeReadExternal
} from "../interfaces/ITradeReadExternal.sol";

contract ExternalProtocolReadFacet {
    /**
     * @notice current buy and sell tax read from TokenDiamond.
     * @return buyTaxBps Current buy tax in BPS
     * @return sellTaxBps Current sell tax in BPS
     */
    function readTokenTaxes()
        external
        view
        returns (
            uint256 buyTaxBps,
            uint256 sellTaxBps
        )
    {
        address tokenDiamond = _getTokenDiamond();

        return ITokenReadExternal(tokenDiamond).getTaxInfo();
    }

    /**
     * @notice retail aur institution sell Reads from TradeDiamond.
     */
    function readTradeSellStatus()
        external
        view
        returns (
            bool retailEnabled,
            bool institutionEnabled
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).getSellStatus();
    }

    /**
     * @notice Retail wallet, sell and cooldown limits reads from TradeDiamond.
     */
    function readRetailLimits()
        external
        view
        returns (
            uint256 walletBps,
            uint256 sellBps,
            uint256 cooldown
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).getRetailLimits();
    }

    /**
     * @notice Micro-sell and panic-sell Reads protection status.
     */
    function readSellProtection()
        external
        view
        returns (
            bool microSellEnabled,
            bool panicSellEnabled
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).getSellProtection();
    }

    /**
     * @notice reads Micro-sell configuration.
     */
    function readMicroSellConfig()
        external
        view
        returns (
            uint256 minLowSell,
            uint256 minHighSell,
            uint256 microSellTaxBps
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).getMicroSellConfig();
    }

    /**
     * @notice Reads Current panic tax levels.
     */
    function readPanicSellTaxes()
        external
        view
        returns (
            uint256 softTaxBps,
            uint256 mediumTaxBps,
            uint256 hardTaxBps,
            uint256 microTaxBps
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).getPanicSellTax();
    }

    /**
     * @notice Reads TradeDiamond's current tax configuration.
     */
    function readTradeTaxConfig()
        external
        view
        returns (
            uint256 currentBuyTax,
            uint256 currentSellTax,
            uint256 buyTaxCap,
            uint256 sellTaxCap
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).getTaxConfig();
    }

    /**
     * @notice Reads AntiBot status aur parameters.
     */
    function readAntiBotConfig()
        external
        view
        returns (
            bool active,
            uint256 tradeWindow,
            uint256 maxTradesPerWindow,
            uint256 restrictionDuration
        )
    {
        address tradeDiamond = _getTradeDiamond();

        active = ITradeReadExternal(tradeDiamond).isAntiBotActive();

        (
            tradeWindow,
            maxTradesPerWindow,
            restrictionDuration
        ) = ITradeReadExternal(tradeDiamond).getAntiBotParams();
    }

    /**
     * @notice pre-check any user's buy eligibility.
     */
    function checkUserBuy(
        address user,
        uint256 amount
    )
        external
        view
        returns (
            bool allowed,
            string memory reason
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).canBuy(user, amount);
    }

    /**
     * @notice pre-check any user's sell eligibility.
     */
    function checkUserSell(
        address user,
        uint256 amount
    )
        external
        view
        returns (
            bool allowed,
            string memory reason
        )
    {
        address tradeDiamond = _getTradeDiamond();

        return ITradeReadExternal(tradeDiamond).canSell(user, amount);
    }

    /**
     * @notice Reads User's remaining retail cooldown.
     */
    function readCooldownRemaining(address user)
        external
        view
        returns (uint256)
    {
        address tradeDiamond = _getTradeDiamond();

        return
            ITradeReadExternal(tradeDiamond)
                .getCooldownRemaining(user);
    }

    /**
     * @notice  return Configured external contract addresses.
     */
    function getExternalProtocolAddresses()
        external
        view
        returns (
            address tokenDiamond,
            address tradeDiamond,
            address pairAddress
        )
    {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        return (
            s.tokenDiamond,
            s.tradeDiamond,
            s.pairAddress
        );
    }

    function _getTokenDiamond()
        internal
        view
        returns (address tokenDiamond)
    {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        require(
            s.initialized,
            "ANALYTICS_NOT_INITIALIZED"
        );

        tokenDiamond = s.tokenDiamond;

        require(
            tokenDiamond != address(0),
            "TOKEN_DIAMOND_NOT_SET"
        );
    }

    function _getTradeDiamond()
        internal
        view
        returns (address tradeDiamond)
    {
        LibAnalyticsStorage.AnalyticsStorage storage s =
            LibAnalyticsStorage.analyticsStorage();

        require(
            s.initialized,
            "ANALYTICS_NOT_INITIALIZED"
        );

        tradeDiamond = s.tradeDiamond;

        require(
            tradeDiamond != address(0),
            "TRADE_DIAMOND_NOT_SET"
        );
    }
}