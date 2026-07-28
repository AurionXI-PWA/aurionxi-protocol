// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;
 
import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibCoreStorage.sol";

import "../interfaces/ITreasuryFacet.sol";
import "../../CoreDiamond/interfaces/ICoreDiamondCut.sol";

/*
|--------------------------------------------------------------------------
| TREASURY MANAGEMENT
|--------------------------------------------------------------------------
| Treasury assets support ecosystem growth, protocol development,
| liquidity initiatives and community incentives.
|--------------------------------------------------------------------------
*/

contract TreasuryFacet is ITreasuryFacet {
    
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(!s.paused, "Trading Paused");
        _;
    }
	
		// In This File has now 9 Functions
		
		// ======== Initialization ========
		function initializeTreasury() external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			
			require(!cs.treasuryInitialized, "Treasury: Already initialized");
			cs.treasuryInitialized = true;
			emit TreasuryInitialized(s.owner, block.timestamp);
		}

		// ======== Balance Management ========
		function deposit() external payable {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			require(msg.value > 0, "ZERO_DEPOSIT");

			cs.treasuryBalance += msg.value;
			cs.totalBalance += msg.value;
			cs.balances[msg.sender] += msg.value;

			emit Deposit(msg.sender, msg.value, cs.treasuryBalance);
		}

		function withdraw(address payable to, uint256 amount) external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			require(to != address(0), "ZERO_RECEIVER");
			require(amount > 0, "INVALID_AMOUNT");
			require(amount <= cs.treasuryBalance, "Treasury: insufficient balance");

			cs.treasuryBalance -= amount;
			cs.totalBalance -= amount;

			(bool success, ) = to.call{value: amount}("");
			require(success, "BNB_TRANSFER_FAILED");

			emit Withdrawal(to, amount, cs.treasuryBalance);
		}

		// ======== Allocation ========
		function allocateFunds(
			address payable to,
			uint256 amount,
			string calldata purpose
		) external onlyOwner {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();

			require(to != address(0), "ZERO_RECEIVER");
			require(amount > 0, "INVALID_AMOUNT");
			require(amount <= cs.treasuryBalance, "Treasury: insufficient balance");

			cs.treasuryBalance -= amount;
			cs.totalBalance -= amount;

			(bool success, ) = to.call{value: amount}("");
			require(success, "BNB_TRANSFER_FAILED");

			emit FundsAllocated(to, amount, purpose);
		}


		// ======== Getters ========
		function treasuryBalance() external view returns (uint256) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			return cs.treasuryBalance;
		}

		function isTreasuryInitialized() external view returns (bool) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			return cs.treasuryInitialized;
		}
		 function getBalance(address account) external view returns (uint256) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			return cs.balances[account];
		}

		function totalTreasuryBalance() external view returns (uint256) {
			LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
			return cs.totalBalance;
		}

	}