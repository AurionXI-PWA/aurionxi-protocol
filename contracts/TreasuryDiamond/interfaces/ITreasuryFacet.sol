// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// @title ITreasuryFacet
// @notice Interface for TreasuryFacet functions
import { ICoreDiamondCut } from "../../CoreDiamond/interfaces/ICoreDiamondCut.sol";

interface ITreasuryFacet
	{

	event Deposit(address indexed from, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed to, uint256 amount, uint256 newBalance);
    event FundsAllocated(address indexed to, uint256 amount, string purpose);
    event TreasuryUpgraded(address indexed treasury);
    event TreasuryInitialized(address indexed owner, uint256 timestamp);

		function initializeTreasury() external;

		function deposit() external payable;
		function withdraw(address payable to, uint256 amount) external;
		
	function allocateFunds(address payable to, uint256 amount, 
											string calldata purpose) external;
				
		function treasuryBalance() external view returns (uint256);
		function isTreasuryInitialized() external view returns (bool);
		function getBalance(address account) external view returns (uint256);
		function totalTreasuryBalance() external view returns (uint256);
	
		
	}

	