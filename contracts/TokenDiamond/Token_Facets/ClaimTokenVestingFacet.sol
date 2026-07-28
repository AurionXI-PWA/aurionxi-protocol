// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";

/*=============================================================================
                           TOKEN VESTING CONFIGURATION
==============================================================================

The following vesting schedules are designed to align long-term incentives,
protect token holders, and ensure sustainable ecosystem growth.

All vesting schedules are released in monthly installments after the cliff
period has ended.

--------------------------------------------------------------------------
FOUNDER
--------------------------------------------------------------------------
Token Amount	 : "31650000",
TGE Release      : 0%
Cliff            : 1,080 Days (36 Months)
Vesting          : 720 Days (24 Months)

Purpose:
Founder allocation remains fully locked for the first three years to
demonstrate long-term commitment and build investor confidence.
After the cliff period, tokens unlock gradually over the next two years
through monthly vesting.

--------------------------------------------------------------------------
CORE TEAM
--------------------------------------------------------------------------
Token Amount	 : "16880000"
TGE Release      : 0%
Cliff            : 720 Days (24 Months)
Vesting          : 720 Days (24 Months)

Purpose:
Core Team tokens remain locked during the critical development phase.
Monthly vesting aligns team incentives with long-term protocol success
and discourages short-term token selling.

--------------------------------------------------------------------------
ADVISORS
--------------------------------------------------------------------------
Token Amount	 : "4220000"
TGE Release      : 0%
Cliff            : 360 Days (12 Months)
Vesting          : 360 Days (12 Months)

Purpose:
Advisor allocations reward strategic guidance while encouraging
continued participation throughout the first two years of the project.

--------------------------------------------------------------------------
MARKETING
--------------------------------------------------------------------------
Token Amount	 : "10550000"
TGE Release      : 10%
Cliff            : 0 Days
Vesting          : 360 Days (12 Months)

Purpose:
A small portion of tokens becomes immediately available for launch
campaigns, partnerships and community growth, while the remaining
allocation vests over one year.

--------------------------------------------------------------------------
ECOSYSTEM
--------------------------------------------------------------------------
Token Amount	 : "31650000"
TGE Release      : 10%
Cliff            : 0 Days
Vesting          : 720 Days (24 Months)

Purpose:
Supports ecosystem expansion, developer incentives, grants,
community initiatives and strategic partnerships through controlled,
long-term token distribution.

--------------------------------------------------------------------------
CENTRALIZED EXCHANGES (CEX)
--------------------------------------------------------------------------
Token Amount	 : "6330000"
TGE Release      : 0%
Cliff            : 180 Days (6 Months)
Vesting          : 360 Days (12 Months)

Purpose:
Exchange allocations remain locked during the initial stabilization
period and are released gradually to support future exchange
partnerships and liquidity planning.

--------------------------------------------------------------------------
GENERAL NOTES
--------------------------------------------------------------------------

• Vesting begins only after the configured cliff period expires.
• Token releases occur in equal monthly installments.
• Users may claim only the amount that has been unlocked.
• Unclaimed vested tokens remain claimable at any time.
• Vesting parameters are intended to support long-term ecosystem
  sustainability and responsible token distribution.

=============================================================================*/

contract ClaimTokenVestingFacet {

	uint256 private constant VESTING_CYCLE = 30 days;
	
	// =====================================================
	//                     EVENTS
	// =====================================================

		event Allocated(
			address indexed user,
			uint256 amount
		);

		event AllocationIncreased(
			address indexed user,
			uint256 amount
		);

		event AllocationReduced(
			address indexed user,
			uint256 amount
		);

		event Claimed(
			address indexed user,
			uint256 amount
		);

		event VestingConfigured(
			uint256 tgePercent,
			uint256 cliffDays,
			uint256 vestingDays
		);

		event UserVestingSet(
			address indexed user
		);

		event ClaimPaused(
			bool status
		);

		event VestingRevoked(
			address indexed user
		);

		event VestingCancelled(
			address indexed user
		);

		event VestingStartChanged(
			address indexed user,
			uint256 startTime
		);

		event Transfer(
			address indexed from,
			address indexed to,
			uint256 value
		);
		
		event AllocationReset(
			address indexed user
		);


		
		event EmergencyWithdraw(
			address indexed to,
			uint256 amount
		);

		error ClaimIsPaused();
		error NothingToClaim();
		error InvalidInput();
		error ZeroAddress();
		error ZeroAmount();
		error VestingRevokedError();
		error VestingCancelledError();
		error InsufficientContractBalance();
		error AllocationTooSmall();


		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
		}

		modifier validAddress(address account) {
			if (account == address(0))
				revert ZeroAddress();
			_;
		}

		modifier validAmount(uint256 amount) {
			if (amount == 0)
				revert ZeroAmount();
			_;
		}
		
		//=================== 1. Admin Function======================
	 		
		function configureGlobalVesting(
			uint256 tgePercent,
			uint256 cliffDays,
			uint256 vestingDays
		)
			external  onlyOwner
		{
			if (tgePercent > 10000)
				revert InvalidInput();
		if (vestingDays > 0 && (vestingDays * 1 days) < VESTING_CYCLE) {
			revert InvalidInput();
		}

		if (vestingDays > 0 && (vestingDays * 1 days) % VESTING_CYCLE != 0) {
			revert InvalidInput();
		}
		
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.globalTGEPercent = tgePercent;
			s.globalCliffDuration = cliffDays * 1 days;
			s.globalVestingDuration = vestingDays * 1 days;

			emit VestingConfigured(
				tgePercent,
				cliffDays,
				vestingDays
			);
		}


		function setClaimPaused(bool status)
			external
			onlyOwner
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.claimPaused = status;

			emit ClaimPaused(status);
		}
		
		// ========== add Validation  =====================
		function setUserVesting(
			address user,
			uint256 tgePercent,
			uint256 cliffDays,
			uint256 vestingDays
		)
			external
			onlyOwner
			validAddress(user)
		{
			if (tgePercent > 10000)
				revert InvalidInput();
		
		if (vestingDays > 0 && (vestingDays * 1 days) < VESTING_CYCLE) {
			revert InvalidInput();
		}

		if (vestingDays > 0 && (vestingDays * 1 days) % VESTING_CYCLE != 0) {
			revert InvalidInput();
		}

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.userTGEPercent[user] = tgePercent;
			s.userCliffDuration[user] = cliffDays * 1 days;
			s.userVestingDuration[user] =
				vestingDays * 1 days;

			emit UserVestingSet(user);
		}

		// If a user's custom vesting needs to be removed 
		// and they need to be switched to global vesting.

		function resetUserConfig(address user)
			external
			onlyOwner
			validAddress(user)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			delete s.userTGEPercent[user];
			delete s.userCliffDuration[user];
			delete s.userVestingDuration[user];

			emit UserVestingSet(user);
		}

		//=================== 2. allocate functions ======================
		// ==================Single wallet allocation. =========
		
		function allocate(
			address user,
			uint256 amount
		)
			external
			onlyOwner
			validAddress(user)
			validAmount(amount)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			if (s.vestingStartTime[user] == 0) {
				s.vestingStartTime[user] = block.timestamp;
			}

			s.vestingAllocated[user] += amount;
			s.totalAllocatedTokens += amount;

			emit Allocated(user, amount);
		}

		//========== By replacing the existing function. =====
		
		function allocateBatch(
			address[] calldata users,
			uint256[] calldata amounts
		)
			external
			onlyOwner
		{
			if (users.length != amounts.length)
				revert InvalidInput();

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			for (uint256 i; i < users.length; i++) {

				if (users[i] == address(0))
					revert ZeroAddress();

				if (amounts[i] == 0)
					revert ZeroAmount();

				if (s.vestingStartTime[users[i]] == 0) {
					s.vestingStartTime[users[i]] =
						block.timestamp;
				}

				s.vestingAllocated[users[i]] += amounts[i];
				s.totalAllocatedTokens += amounts[i];

				emit Allocated(users[i], amounts[i]);
			}
		}
		
		// ====== Useful after DAO vote or founder bonus. ========
		
		function increaseAllocation(
			address user,
			uint256 amount
		)
			external
			onlyOwner
			validAddress(user)
			validAmount(amount)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			if (s.vestingStartTime[user] == 0) {
				s.vestingStartTime[user] = block.timestamp;
			}

			s.vestingAllocated[user] += amount;
			s.totalAllocatedTokens += amount;

			emit AllocationIncreased(user, amount);
		} 
		
		// ============ Reduction. =================
		
		function decreaseAllocation(
			address user,
			uint256 amount
		)
			external
			onlyOwner
			validAddress(user)
			validAmount(amount)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			if (s.vestingAllocated[user] < amount) {
				revert AllocationTooSmall();
			}

			uint256 newAllocation =
				s.vestingAllocated[user] - amount;

			if (newAllocation < s.vestingClaimed[user]) {
				revert InvalidInput();
			}

			s.vestingAllocated[user] = newAllocation;
			s.totalAllocatedTokens -= amount;

			emit AllocationReduced(user, amount);
		}
		
		// ========== Complete allocation remove. ==================
		
		function resetAllocation(
			address user
		)
			external
			onlyOwner
			validAddress(user)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			uint256 oldAllocated =
				s.vestingAllocated[user];

			uint256 oldClaimed =
				s.vestingClaimed[user];

			if (oldAllocated > 0) {
				s.totalAllocatedTokens -= oldAllocated;
			}

			if (oldClaimed > 0) {
				s.totalClaimedTokens -= oldClaimed;
			}

			delete s.vestingAllocated[user];
			delete s.vestingClaimed[user];
			delete s.vestingStartTime[user];

			delete s.userTGEPercent[user];
			delete s.userCliffDuration[user];
			delete s.userVestingDuration[user];

			delete s.vestingRevoked[user];
			delete s.vestingCancelled[user];

			emit AllocationReset(user);
		}
		
		// Set or correct vesting start time for a project wallet
		function setVestingStart(
			address user,
			uint256 timestamp
		)
			external
			onlyOwner
			validAddress(user)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.vestingStartTime[user] = timestamp;

			emit VestingStartChanged(
				user,
				timestamp
			);
		}
		
		//=== Employee leaves company. Already claimed tokens remain. =======
		// ===== Future claim stops. ===========
		
		function revokeVesting(
			address user
		)
			external
			onlyOwner
			validAddress(user)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.vestingRevoked[user] = true;

			emit VestingRevoked(user);
		}

		// ========== Permanent cancel ================
		
		function cancelVesting(
			address user
		)
			external
			onlyOwner
			validAddress(user)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.vestingCancelled[user] = true;

			emit VestingCancelled(user);
		}
		
		//========= Mistake se revoke ho gaya ============
		
		function restoreVesting(
			address user
		)
			external
			onlyOwner
			validAddress(user)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.vestingRevoked[user] = false;
			s.vestingCancelled[user] = false;
		}


		function _getUserConfig(address user)
			internal
			view
			returns (
				uint256 tge,
				uint256 cliff,
				uint256 duration
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			tge = s.userTGEPercent[user] > 0
				? s.userTGEPercent[user]
				: s.globalTGEPercent;

			cliff = s.userCliffDuration[user] > 0
				? s.userCliffDuration[user]
				: s.globalCliffDuration;

			duration = s.userVestingDuration[user] > 0
				? s.userVestingDuration[user]
				: s.globalVestingDuration;
		}

		//=== This is the heart of the entire Westinghouse engine. ===
		function getUnlocked(address user)
			public
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			if (s.vestingCancelled[user])
				return 0;

			uint256 total = s.vestingAllocated[user];

			if (total == 0)
				return 0;

			uint256 start = s.vestingStartTime[user];

			if (start == 0)
				return 0;

			(
				uint256 tgePercent,
				uint256 cliff,
				uint256 duration
			) = _getUserConfig(user);

			uint256 tgeUnlock =
				(total * tgePercent) / 10000;

			uint256 cliffEnd =
				start + cliff;

			if (block.timestamp < cliffEnd) {
				return tgeUnlock;
			}

			if (duration == 0) {
				return total;
			}

			uint256 totalCycles =
				duration / VESTING_CYCLE;

			if (totalCycles == 0) {
				return total;
			}

			uint256 elapsed =
				block.timestamp - cliffEnd;

			uint256 completedCycles =
				elapsed / VESTING_CYCLE;

			if (completedCycles >= totalCycles) {
				return total;
			}

			uint256 remaining =
				total - tgeUnlock;

			uint256 cycleUnlock =
				(remaining * completedCycles) / totalCycles;

			return tgeUnlock + cycleUnlock;
		}


		function getLockedAmount(address user)
			public
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			uint256 total =
				s.vestingAllocated[user];

			uint256 unlocked =
				getUnlocked(user);

			if (total <= unlocked)
				return 0;

			return total - unlocked;
		}

		function getClaimable(address user)
			public
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			if (s.vestingCancelled[user])
				return 0;

			if (s.vestingRevoked[user])
				return 0;

			uint256 unlocked =
				getUnlocked(user);

			uint256 claimed =
				s.vestingClaimed[user];

			if (unlocked <= claimed)
				return 0;

			return unlocked - claimed;
		}

		function getReleasedAmount(address user)
			public
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return s.vestingClaimed[user];
		}


		function getRemainingAmount(address user)
			public
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			uint256 total =
				s.vestingAllocated[user];

			uint256 claimed =
				s.vestingClaimed[user];

			if (claimed >= total)
				return 0;

			return total - claimed;
		}

		function getVestingEnd(address user)
			public
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			(
				,
				uint256 cliff,
				uint256 duration
			) = _getUserConfig(user);

			return
				s.vestingStartTime[user]
				+ cliff
				+ duration;
		}

		function isCliffFinished(address user)
			public
			view
			returns (bool)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			(
				,
				uint256 cliff,

			) = _getUserConfig(user);

			return
				block.timestamp >=
				s.vestingStartTime[user] + cliff;
		}


		function canClaim(address user)
			public
			view
			returns (bool)
		{
			if (getClaimable(user) > 0)
				return true;

			return false;
		}

		function isFullyClaimed(address user)
			public
			view
			returns (bool)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return
				s.vestingClaimed[user] >=
				s.vestingAllocated[user];
		}

		// =====================================================
		// ================= INTERNAL CLAIM =====================
		// =====================================================

		function _claim(
			address beneficiary,
			address receiver
		) internal {

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			if (s.claimPaused)
				revert ClaimIsPaused();

			if (s.vestingCancelled[beneficiary])
				revert VestingCancelledError();

			if (s.vestingRevoked[beneficiary])
				revert VestingRevokedError();

			uint256 amount = getClaimable(beneficiary);

			if (amount == 0)
				revert NothingToClaim();

			address contractAddr = address(this);

			if (s.balances[contractAddr] < amount)
				revert InsufficientContractBalance();

			// Effects
			s.vestingClaimed[beneficiary] += amount;
			s.totalClaimedTokens += amount;

			// Interaction (internal ledger update)
			s.balances[contractAddr] -= amount;
			s.balances[receiver] += amount;

			emit Transfer(
				contractAddr,
				receiver,
				amount
			);

			emit Claimed(
				beneficiary,
				amount
			);
		}

		function claim() external {

			_claim(
				msg.sender,
				msg.sender
			);

		}

		// === Useful if the beneficiary wishes to receive funds in another wallet. ==
		function claimTo(
			address receiver
		)
			external
			validAddress(receiver)
		{

			_claim(
				msg.sender,
				receiver
			);

		}

		// =====================================================
		// ================= CLAIM ALL ==========================
		// =====================================================

		function claimAll() external {

			_claim(
				msg.sender,
				msg.sender
			);

		}

		//=========== Owner emergency token recovery. ===========
		function emergencyWithdrawExcess(
			address to,
			uint256 amount
		)
			external
			onlyOwner
			validAddress(to)
			validAmount(amount)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			uint256 excess =
				getExcessVestingReserve();

			if (amount > excess) {
				revert InsufficientContractBalance();
			}

			address contractAddr =
				address(this);

			s.balances[contractAddr] -= amount;
			s.balances[to] += amount;

			emit Transfer(contractAddr, to, amount);
			emit EmergencyWithdraw(to, amount);
		}
		
		function emergencyWithdrawAllExcess(
			address to
		)
			external
			onlyOwner
			validAddress(to)
		{
			uint256 excess =
				getExcessVestingReserve();

			if (excess == 0) {
				revert InsufficientContractBalance();
			}

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			address contractAddr =
				address(this);

			s.balances[contractAddr] -= excess;
			s.balances[to] += excess;

			emit Transfer(contractAddr, to, excess);
			emit EmergencyWithdraw(to, excess);
		}

		function getExcessVestingReserve()
			public
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			address contractAddr = address(this);

			uint256 reserveBalance =
				s.balances[contractAddr];

			uint256 requiredReserve =
				s.totalAllocatedTokens - s.totalClaimedTokens;

			if (reserveBalance <= requiredReserve) {
				return 0;
			}

			return reserveBalance - requiredReserve;
		}
		  

		// ============== View Functions & Dashboard ============
		
		function getUserSummary(address user)
			external
			view
			returns (
				uint256 allocated,
				uint256 unlocked,
				uint256 claimed,
				uint256 claimable,
				uint256 locked,
				uint256 remaining,
				uint256 startTime,
				uint256 endTime,
				bool canUserClaim,
				bool revoked,
				bool cancelled
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			allocated = s.vestingAllocated[user];
			unlocked = getUnlocked(user);
			claimed = s.vestingClaimed[user];
			claimable = getClaimable(user);
			locked = getLockedAmount(user);
			remaining = getRemainingAmount(user);

			startTime = s.vestingStartTime[user];
			endTime = getVestingEnd(user);

			canUserClaim = canClaim(user);

			revoked = s.vestingRevoked[user];
			cancelled = s.vestingCancelled[user];
		}

		function getGlobalVesting()
			external
			view
			returns (
				uint256 tgePercent,
				uint256 cliffDuration,
				uint256 vestingDuration,
				bool paused
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return (
				s.globalTGEPercent,
				s.globalCliffDuration,
				s.globalVestingDuration,
				s.claimPaused
			);
		}

		function getUserConfig(address user)
			external
			view
			returns (
				uint256 tgePercent,
				uint256 cliffDuration,
				uint256 vestingDuration
			)
		{
			return _getUserConfig(user);
		}

		function totalAllocated()
			external
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return s.totalAllocatedTokens;
		}

		function totalClaimed()
			external
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return s.totalClaimedTokens;
		}

		function totalRemaining()
			external
			view
			returns (uint256)
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

			if (s.totalClaimedTokens >= s.totalAllocatedTokens) {
				return 0;
			}

			return s.totalAllocatedTokens - s.totalClaimedTokens;
		}

		function getUserVesting(address user)
			external
			view
			returns (
				uint256 allocated,
				uint256 claimed,
				uint256 unlocked,
				uint256 claimable,
				uint256 locked
			)
		{
			allocated = LibAppStorage.diamondStorage().vestingAllocated[user];
			claimed = LibAppStorage.diamondStorage().vestingClaimed[user];
			unlocked = getUnlocked(user);
			claimable = getClaimable(user);
			locked = getLockedAmount(user);
		}

		function getVestingStatus(address user)
			external
			view
			returns (
				bool isRevoked,
				bool isCancelled,
				bool cliffFinished,
				bool fullyClaimed,
				bool claimEnabled
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			isRevoked = s.vestingRevoked[user];
			isCancelled = s.vestingCancelled[user];
			cliffFinished = isCliffFinished(user);
			fullyClaimed = isFullyClaimed(user);
			claimEnabled = canClaim(user);
		}

	}
	
	
	