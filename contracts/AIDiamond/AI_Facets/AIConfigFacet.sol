// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibAIStorage } from "../../libraries/LibAIStorage.sol";
import { IAIConfigFacet } from "../interfaces/IAIConfigFacet.sol";

contract AIConfigFacet is IAIConfigFacet {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    function initializeAI(
        address tokenDiamond,
        address tradeDiamond,
        address analyticDiamond,
        address oracleReporter
    ) external override onlyOwner {
        require(tokenDiamond != address(0), "TOKEN_REQUIRED");
        require(analyticDiamond != address(0), "ANALYTICS_REQUIRED");

        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();
        require(!s.initialized, "AI_ALREADY_INITIALIZED");

        s.tokenDiamond = tokenDiamond;
        s.tradeDiamond = tradeDiamond;
        s.analyticDiamond = analyticDiamond;
        s.oracleReporter = oracleReporter;
        s.initialized = true;

        emit AIInitialized(tokenDiamond, tradeDiamond, analyticDiamond, oracleReporter);
        emit AIOracleReporterUpdated(oracleReporter);
    }

    function setAIOracleReporter(address reporter)
        external
        override
        onlyOwner
    {
        LibAIStorage.aiStorage().oracleReporter = reporter;
        emit AIOracleReporterUpdated(reporter);
    }

    function setAIReportingPaused(bool paused)
        external
        override
        onlyOwner
    {
        LibAIStorage.aiStorage().reportingPaused = paused;
        emit AIReportingPausedUpdated(paused);
    }

    function getAIConfig()
        external
        view
        override
        returns (
            address tokenDiamond,
            address tradeDiamond,
            address analyticDiamond,
            address oracleReporter,
            bool initialized,
            bool reportingPaused
        )
    {
        LibAIStorage.AIStorage storage s = LibAIStorage.aiStorage();

        return (
            s.tokenDiamond,
            s.tradeDiamond,
            s.analyticDiamond,
            s.oracleReporter,
            s.initialized,
            s.reportingPaused
        );
    }
}