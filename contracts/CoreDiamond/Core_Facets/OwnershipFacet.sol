// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { IOwnershipFacet } from "../interfaces/IOwnershipFacet.sol";

/*
|--------------------------------------------------------------------------
| OWNERSHIP MANAGEMENT
|--------------------------------------------------------------------------
| Ownership controls administrative permissions of the protocol.
|
| Ownership should remain secured and transferred only through
| authorized governance procedures.
|--------------------------------------------------------------------------
*/

contract OwnershipFacet is IOwnershipFacet
	{
		// Custom error
		error NewOwnerIsZeroAddress();

		// Modifier
		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
		}

		// Getter
		function owner() external view returns (address) {
			return LibDiamond.contractOwner();
		}

		// Setter
		function transferOwnership(address newOwner) external override onlyOwner 
		{
			if (newOwner == address(0)) revert NewOwnerIsZeroAddress();
			LibDiamond.setContractOwner(newOwner);

		}
	}
	
	