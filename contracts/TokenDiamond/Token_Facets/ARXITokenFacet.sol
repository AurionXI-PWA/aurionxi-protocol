// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibCoreStorage.sol";
import "../interfaces/IARXIToken.sol";

import "../../CoreDiamond/interfaces/ICoreDiamond.sol";

/*
|--------------------------------------------------------------------------
| BLACKLIST POLICY
|--------------------------------------------------------------------------
| The blacklist exists solely to protect the protocol, its holders,
| and ecosystem against malicious activities.
|
| A wallet may be blacklisted only under exceptional circumstances such as:
|
| - Proven smart contract exploits or attack attempts.
| - Flash-loan based market manipulation.
| - Liquidity draining or protocol abuse.
| - Repeated bot attacks that threaten normal trading.
| - Compliance with legally binding regulatory or court orders,
|   where applicable.
|
| The blacklist MUST NOT be used to restrict normal investors,
| suppress legitimate trading, or manipulate the market.
|
| Whenever possible, blacklist actions should be documented
| and remain transparent to the community.
|--------------------------------------------------------------------------
*/
/*
|--------------------------------------------------------------------------
| EMERGENCY MODE
|--------------------------------------------------------------------------
| Emergency Mode exists to protect the protocol during critical
| security incidents, active exploits or infrastructure failures.
|
| It should only be enabled temporarily until the issue has been
| investigated and resolved.
|--------------------------------------------------------------------------
*/
/*
|--------------------------------------------------------------------------
| PAUSE MECHANISM
|--------------------------------------------------------------------------
| The pause mechanism temporarily suspends selected protocol
| operations during upgrades, maintenance or security incidents.
|
| Normal operation should resume as soon as the protocol is safe.
|--------------------------------------------------------------------------
*/

contract ARXITokenFacet is IARXIToken {
    using LibAppStorage for LibAppStorage.AppStorage;

    
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
	
	// =============================================================
	//  EMERGENCY MODE
	// =============================================================

	function enableEmergencyMode() external onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.emergencyMode = true;
		}
		
	function disableEmergencyMode() external onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.emergencyMode = false;
		}
	function isEmergencyMod() external view returns (bool) {
			return LibAppStorage.diamondStorage().emergencyMode;
		}
	// =============================================================
	//  EMERGENCY / PAUSE / UNPAUSE
	// =============================================================
	
	function pause() external onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.paused = true;
		emit Paused(msg.sender, block.timestamp);
		}

	function unpause() external onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.paused = false;
		emit Unpaused(msg.sender, block.timestamp);
		}
		
	function isPaused() external view override returns (bool) {
	return LibAppStorage.diamondStorage().paused;
		}
		
	// =============================================================
	//  TOKEN MINTING & BURNING
	// =============================================================

	function burn(uint256 amount) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(s.balances[msg.sender] >= amount, "Insufficient balance");

		s.balances[msg.sender] -= amount;
		s.totalSupply -= amount;
		emit TokensBurned(msg.sender, amount, s.totalSupply);
		}

	// Mint tokens to a recipient (only authorized minters or owner)
	function mint(address to, uint256 amount) external override {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
		if (!s.isAuthorizedMinter[msg.sender]) {
			LibDiamond.enforceIsContractOwner();
		}

		require(to != address(0), "ZERO_ADDRESS");
		require(amount > 0, "ZERO_AMOUNT");
		require(s.totalSupply + amount <= s.maxSupply, "Exceeds MAXSUPPLY");

		s.balances[to] += amount;
		s.totalSupply += amount;

		emit TokensMinted(to, amount, s.totalSupply);
	}

	// Authorize or revoke a minter (only owner)
	function setAuthorizedMinter(address minter, bool enabled) 
		external override onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		s.isAuthorizedMinter[minter] = enabled;
		emit MinterUpdated(minter, enabled);
		}
	
	function isAuthorizedMinter(address minter) external view returns (bool) {
        return LibAppStorage.diamondStorage().isAuthorizedMinter[minter];
		}
	
	// =============================================================
	//  LIQUIDITY & MARKET PAIRS
	// =============================================================

	function setLPPair(address pair, bool enabled) external override onlyOwner 
		{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			require(pair != address(0), "Invalid LP address");
			
			s.isLpPair[pair] = enabled;

			if (enabled) {
				s.pairAddress = pair;
			} else if (s.pairAddress == pair) {
				s.pairAddress = address(0);
			}

			emit LPPairUpdated(pair, enabled);
		}

	function setMarketPair(address account, bool value) 
		external override onlyOwner {
		
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(account != address(0), "Invalid market address");
				
		s.isMarketPair[account] = value;
		emit MarketPairUpdated(account, value);
		}
	
	function registerPair(address pair) external onlyOwner {
		
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
		s.pairAddress = pair;
		s.isLpPair[pair] = true;
		}
		
	// =============================================================
	//  BLACKLIST MANAGEMENT
	// =============================================================

	function setBlacklist(address account, bool status) 
		external override onlyOwner {
		
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(account != address(0), "Invalid address");
		
		s.blacklist[account] = status;
		emit BlacklistUpdated(account, status);
		}

	function setBlacklistEnabled(bool enabled) external override onlyOwner {
		
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
		s.blacklistEnabled = enabled;
		emit BlacklistEnabledUpdated(enabled);
		}
	
	// ======================================================
	// Listing timestamp setup
	// ======================================================
	function setListingTimestamp(uint256 ts) external override onlyOwner {
		
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(!s.listingActive, "already set");
		
		s.listingTimestamp = ts;
		s.listingActive = true;

		emit ListingTimestampSet(ts);
		}

	}
  
  
  