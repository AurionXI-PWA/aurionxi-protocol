// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { LibAppStorage } from "../../libraries/LibAppStorage.sol";

interface ICoreEmergencyRead {
    function isGuardianEmergencyApproved() external view returns (bool);
}

contract EmergencyRecoveryFacet {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ForceBurnExecuted(address target, uint256 amount);
    event TokensConfiscated(address from, address to, uint256 amount);

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier emergencyApproved() {
        address core = LibCoreStorage.coreStorage().coreDiamond;
        require(core != address(0), "CORE_NOT_SET");
        require(
            ICoreEmergencyRead(core).isGuardianEmergencyApproved(),
            "NO_GUARDIAN_APPROVAL"
        );
        _;
    }

    function forceBurn(address target, uint256 amount)
        external
        onlyOwner
        emergencyApproved
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        require(target != address(0), "ZERO_TARGET");
        require(amount > 0, "ZERO_AMOUNT");
        require(s.balances[target] >= amount, "INSUFFICIENT");

        s.balances[target] -= amount;
        s.totalSupply -= amount;

        emit Transfer(target, address(0), amount);
        emit ForceBurnExecuted(target, amount);
    }

    function confiscate(address from, address to, uint256 amount)
        external
        onlyOwner
        emergencyApproved
    {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        require(from != address(0), "ZERO_FROM");
        require(to != address(0), "ZERO_TO");
        require(amount > 0, "ZERO_AMOUNT");
        require(s.balances[from] >= amount, "INSUFFICIENT");

        s.balances[from] -= amount;
        s.balances[to] += amount;

        emit Transfer(from, to, amount);
        emit TokensConfiscated(from, to, amount);
    }
}