// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { ICoreDiamondCut } from "../interfaces/ICoreDiamondCut.sol";

// @title ICoreFacet
// @notice Interface for CoreFacet functions and state variables
interface ICoreFacet 
	{
 
	event DiamondRegistered(address child, uint256 index, string name);
    event DiamondRemoved(address indexed child);
	event ChildDiamondUpgraded(address indexed child, uint256 index);
	event ChildOwnerBound(address indexed child, address indexed owner);
	
	function deployChildDiamondThroughFactory(
		address factory, bytes memory bytecode, bytes32 salt) external;

	function checkCoreDiamond() external view returns (address);
	function checkChildDiamondOwner(address childDiamond) external view returns (address);
					
    function unlockRegistry() external;
    function lockRegistry() external;

    function registerDiamond(address _child, string calldata _name) external;
	function getChildIndex(address child) external view returns (uint256);
    function removeDiamond(address _child) external;

		
}	
	