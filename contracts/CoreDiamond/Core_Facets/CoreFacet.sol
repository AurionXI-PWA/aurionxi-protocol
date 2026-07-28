// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { ICoreDiamondCut } from "../interfaces/ICoreDiamondCut.sol";
import { LibAurionXIStorage } from "../../libraries/LibAurionXIStorage.sol";

import { ICoreFacet } from "../interfaces/ICoreFacet.sol";
import "../../factory/Create2Factory.sol";  // path adjust karo

error ChildIsZeroAddress();
contract CoreFacet is ICoreFacet
	{	
		
		modifier onlyOwner() 
		{	LibDiamond.enforceIsContractOwner();
			_;
		}
			
		//Deploy helper function 
		function deployChildDiamondThroughFactory(
			address factory, bytes memory bytecode, bytes32 salt
			) external onlyOwner 
			{
				Create2Factory(factory).deployChildDiamond(bytecode, salt);
			}

		// @notice Returns the CoreDiamond address bound in CoreStorage
		function checkCoreDiamond() external view returns (address) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			return cs.coreDiamond;
		}

		// @notice Returns the owner address of a specific child diamond (if mapping used)
		function checkChildDiamondOwner(address childDiamond) external view returns (address) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			return cs.childOwners[childDiamond];
		}
	

		// @notice Unlock registry (false = allow new diamonds again)
		function unlockRegistry() external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		cs.registryLocked = false;
		}
		
		// @notice Lock registry (no new diamonds can be added)
		function lockRegistry() external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			cs.registryLocked = true;
		}
		 
		
		// @notice Register a new child diamond and bind its owner to CoreDiamond
	function registerDiamond(address _child, string calldata _name) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(!cs.registryLocked, "Registry is locked");
		require(_child != address(0), "Invalid child diamond address");
		require(!cs.registeredDiamonds[_child], "Diamond already registered");

		cs.childDiamonds.push(_child);
		cs.diamondCount++;
		cs.registeredDiamonds[_child] = true;
		cs.diamondNames[_child] = _name;
		cs.childOwners[_child] = cs.coreDiamond;

		uint256 index = cs.childDiamonds.length - 1;

		emit DiamondRegistered(_child, index, _name);
		emit ChildOwnerBound(_child, cs.coreDiamond);
	}
		
		// AFTER Register GET CHILD Index
		function getChildIndex(address child) external view returns (uint256) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			for (uint256 i = 0; i < cs.childDiamonds.length; i++) {
				if (cs.childDiamonds[i] == child) {
					return i;
					}
				}
				revert("Child not found");
			}

	function removeDiamond(address _child) external onlyOwner {
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

		require(!cs.registryLocked, "Registry is locked");
		require(cs.registeredDiamonds[_child], "Diamond not registered");

		uint256 length = cs.childDiamonds.length;
		bool found = false;

		for (uint256 i = 0; i < length; i++) {
			if (cs.childDiamonds[i] == _child) {
				found = true;

				cs.childDiamonds[i] = cs.childDiamonds[length - 1];
				cs.childDiamonds.pop();

				cs.diamondCount--;

				delete cs.registeredDiamonds[_child];
				delete cs.diamondNames[_child];
				delete cs.childOwners[_child];

				emit DiamondRemoved(_child);
				break;
				}
			}
			require(found, "Diamond not found in registry");
		}
 
		
	}
 
