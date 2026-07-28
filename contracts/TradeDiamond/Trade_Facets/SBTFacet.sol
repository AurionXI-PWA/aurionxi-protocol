// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "../interfaces/ISBT.sol";

contract SBTFacet {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    event SBTSellRequirementsUpdated(
        bool retailSellRequired,
        bool institutionSellRequired
    );
	event SBTContractUpdated(address indexed sbtContract);
	event SBTCheckEnabledUpdated(bool enabled);


    //========== Enable-Disable SBT checking ==============
	function setSBTCheckEnabled(bool enabled) external onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (enabled) {
			require(s.sbtContract != address(0), "SBT_CONTRACT_NOT_SET");
		}

		s.sbtCheckEnabled = enabled;

		emit SBTCheckEnabledUpdated(enabled);
	}

	function setSBTContract(address sbtContract) external onlyOwner {
		require(sbtContract != address(0), "SBT_ZERO_ADDRESS");

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.sbtContract = sbtContract;

		emit SBTContractUpdated(sbtContract);
	}
	
	//======================================
	// SBT SELL REQUIREMENTS
	//======================================
    function setSBTSellRequirements(
        bool retailSellRequired,
        bool institutionSellRequired
    ) external onlyOwner {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        s.sbtRetailSellRequired = retailSellRequired;
        s.sbtInstitutionSellRequired = institutionSellRequired;

        emit SBTSellRequirementsUpdated(
            retailSellRequired,
            institutionSellRequired
        );
    }

    function hasValidSBT(address user) public view returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        if (!s.sbtCheckEnabled || user == address(0) || s.sbtContract == address(0)) {
			return false;
		}

        try ISBT(s.sbtContract).balanceOf(user) returns (uint256 balance) {
            return balance > 0;
        } catch {
            return false;
        }
    }

    function getSBTLevel(address user) external view returns (string memory) {
        return hasValidSBT(user) ? "AID-Verified" : "Unverified";
    }

    function enforceSBTBuy(address buyer, bool isInstitution) external view {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        if (!isInstitution) {
            return;
        }

        if (!s.institutionSBTRequired[buyer]) {
            return;
        }

        require(s.sbtContract != address(0), "AurionXI: SBT contract not set");
        require(
            ISBT(s.sbtContract).balanceOf(buyer) > 0,
            "AurionXI: Institution requires SBT to buy"
        );
    }

    function enforceSBTSell(address seller, bool isInstitution) external view {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        bool required = isInstitution
            ? s.institutionSBTRequired[seller] || s.sbtInstitutionSellRequired
            : s.sbtRetailSellRequired;

        if (!required) {
            return;
        }

        require(s.sbtContract != address(0), "AurionXI: SBT contract not set");
        require(
            ISBT(s.sbtContract).balanceOf(seller) > 0,
            isInstitution
                ? "AurionXI: Institution must hold SBT to sell"
                : "AurionXI: Retail must hold SBT to sell"
        );
    }

    function getSBTConfig()
        external
        view
        returns (
            address sbtContract,
            bool enabled,
            bool retailSellRequired,
            bool institutionSellRequired
        )
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        return (
            s.sbtContract,
            s.sbtCheckEnabled,
            s.sbtRetailSellRequired,
            s.sbtInstitutionSellRequired
        );
    }
}