// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


/* ==============================================================
   FeeFacet.sol — AurionXI Modular Fee Distribution System
   --------------------------------------------------------------
   ✅ Handles all fee logic and wallet splits
   ✅ Controlled via the Diamond owner (Upgradeable)
   ✅ Safe 100% ratio validation
   ✅ Integrates with LibAppStorage shared state
   ============================================================== */

import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibDiamond.sol";
import "../interfaces/IFeeFacet.sol";

contract FeeFacet is  IFeeFacet
	{
		modifier onlyOwner() {
			LibDiamond.enforceIsContractOwner();
			_;
		}

	// ============================================================
	//           Fee collector split all wallet require
	// ============================================================
	//       WALLET LOCK / UNLOCK (FLEXIBLE CONTROL)
	// ============================================================
	 
	function setWalletsLock(bool locked)  external override onlyOwner{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.walletsLocked = locked;
		emit WalletsLockUpdated(locked);
	}
	
	
	// 1. Set all core wallets (update anytime)
	
	function setCoreWalletsUpdated(
		address _treasuryWallet,
		address _rewardDistributor,
		address _liquidityLocker,
		address _marketingWallet,
		address _burnWallet
	) external override onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		require(!s.walletsLocked, "Core wallets locked");
		require(_treasuryWallet != address(0), "Invalid treasury");
		require(_rewardDistributor != address(0), "Invalid reward");
		require(_liquidityLocker != address(0), "Invalid liquidity");
		require(_marketingWallet != address(0), "Invalid marketing");
		require(_burnWallet != address(0), "Invalid burn");

		s.treasuryWallet = 		_treasuryWallet;
		s.rewardDistributor = 	_rewardDistributor;
		s.liquidityLocker = 	_liquidityLocker;
		s.marketingWallet = 	_marketingWallet;
		s.burnWallet = 			_burnWallet;

		emit CoreWalletsUpdated(_treasuryWallet, _rewardDistributor, _liquidityLocker, _marketingWallet, _burnWallet);
	}
    
	// 2. SAFE FEE SPLIT & DISTRIBUTION SYSTEM
	function setFeeSplitWallet(
		uint256 _treasuryShare,
		uint256 _rewardShare,
		uint256 _liquidityShare,
		uint256 _marketingShare,
		uint256 _burnShare
		) external override onlyOwner {
		
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		uint256 totalShare = _treasuryShare + _rewardShare + _liquidityShare + _marketingShare + _burnShare;
		require(totalShare == 100, "Split total must equal 100%");

		s.treasuryShare = _treasuryShare;
		s.rewardShare = _rewardShare;
		s.liquidityShare = _liquidityShare;
		s.marketingShare = _marketingShare;
		s.burnShare = _burnShare;

		emit FeeSplitWalletUpdated(_treasuryShare, _rewardShare, _liquidityShare, _marketingShare, _burnShare);
	}

    // ==============================================================
    //                        FEE DISTRIBUTION
    // ==============================================================

    // 3. @notice Manually distribute all tokens from FeeCollector based on configured split ratios
    
	function distributeFees() external override onlyOwner {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
		require(s.feeCollector != address(0), "AurionXI: Fee collector not set");
		uint256 balance = s.balances[s.feeCollector];
        require(balance > 0, "AurionXI: No FEE balance to distribute");
		
        uint256 totalShare = s.treasuryShare + s.rewardShare + s.liquidityShare + s.marketingShare + s.burnShare;
        require(totalShare == 100, "AurionXI: Shares must total 100%");
        
        // Calculate shares
        uint256 tShare = (balance * s.treasuryShare) / 100;
        uint256 rShare = (balance * s.rewardShare) / 100;
        uint256 lShare = (balance * s.liquidityShare) / 100;
        uint256 mShare = (balance * s.marketingShare) / 100;
        uint256 bShare = (balance * s.burnShare) / 100;
		
		// clear fee collector balance
        //s.balances[s.feeCollector] = 0;
		
        // Transfer logic (internal balance-based, no external token calls)
        s.balances[s.feeCollector] -= balance;
        s.balances[s.treasuryWallet] += tShare;
        s.balances[s.rewardDistributor] += rShare;
        s.balances[s.liquidityLocker] += lShare;
        s.balances[s.marketingWallet] += mShare;
		s.balances[s.burnWallet] += bShare;
		
        // Burn tokens (reduce total supply)
        s.totalSupply -= bShare;
		
		// ERC20 visibility
        emit Transfer(s.feeCollector, s.treasuryWallet, tShare);
        emit Transfer(s.feeCollector, s.rewardDistributor, rShare);
        emit Transfer(s.feeCollector, s.liquidityLocker, lShare);
        emit Transfer(s.feeCollector, s.marketingWallet, mShare);
        emit Transfer(s.feeCollector, s.burnWallet, bShare);

        emit FeeDistributedDetailed(tShare, rShare, lShare, mShare, bShare, block.timestamp);
	}

    // ==============================================================
    //                        VIEW FUNCTIONS
    // ==============================================================
	// 1. Get WALLET address
	
	function getAllWalletsAddress() external view override returns 
			(
			address feeCollector_,
            address treasuryWallet_,
            address rewardWallet_,
            address liquidityWallet_,
            address marketingWallet_,
            address burnWallet_
			)
			{
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return (
			s.feeCollector,
            s.treasuryWallet,
			s.rewardDistributor,
			s.liquidityLocker,
            s.marketingWallet,
            s.burnWallet  
			);
			}
    
	//2. View current fee split percentages
    function getFeeSplit() external view override returns (
            uint256 treasuryShare,
            uint256 rewardShare,
            uint256 liquidityShare,
            uint256 marketingShare,
            uint256 burnShare
        ) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.treasuryShare, s.rewardShare, s.liquidityShare, s.marketingShare, s.burnShare);
		}	
	
	// GET WALLET BALANCES
    function getWalletBalances() external view override returns (
			uint256 feeCollectorBalance,
			uint256 treasuryBalance,
			uint256 rewardBalance,
			uint256 liquidityBalance,
			uint256 marketingBalance,
			uint256 burnBalance
		) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			return (
				s.balances[s.feeCollector],
				s.balances[s.treasuryWallet],
				s.balances[s.rewardDistributor],
				s.balances[s.liquidityLocker],
				s.balances[s.marketingWallet],
				s.balances[s.burnWallet]
			);
		}

		
		// ------------------------------------------------------------------------
		//  OWNER FUNCTION — Set Fee Collector & Auto-Exempt from Fees
		// ------------------------------------------------------------------------
		function setFeeCollector(address collector) external override onlyOwner {
			require(collector != address(0), "Zero address");
		
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			s.feeCollector = collector;
			s.isFeeExempt[collector] = true;
			
			emit FeeCollectorUpdated(collector);
			}

		// ------------------------------------------------------------------------
		//  OWNER FUNCTION — Manage Fee Exemption for Any Address
		// ------------------------------------------------------------------------
		function setFeeExempt(address account, bool exempt) external override onlyOwner {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			s.isFeeExempt[account] = exempt;
			}		
		
		function isExemptFromLimits(address account) public view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return (
			s.isLpPair[account] ||
			s.isMarketPair[account] ||
			account == s.pairAddress ||
			s.isFeeExempt[account]
				);
			}
					
		function setExcludedFromFee(address account, bool excluded) 
		external override onlyOwner {
			require(account != address(0), "ZERO_ADDRESS");

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.isExcludedFromFee[account] = excluded;
			emit ExcludedFromFeeUpdated(account, excluded);
		}

		function setExcludedFromLimits(address account, bool excluded
		) external override onlyOwner {
			require(account != address(0), "ZERO_ADDRESS");

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.isExcludedFromLimits[account] = excluded;
			emit ExcludedFromLimitsUpdated(account, excluded);
		}

		function setExemptFromLimits(address account, bool exempt
		) external override onlyOwner {
			require(account != address(0), "ZERO_ADDRESS");

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.isExemptFromLimits[account] = exempt;
			emit ExemptFromLimitsUpdated(account, exempt);
		}

		function setAutomatedMarketMakerPair(address pair, bool enabled
		) external override onlyOwner {
			require(pair != address(0), "ZERO_PAIR");

			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			s.automatedMarketMakerPairs[pair] = enabled;

			// Keep existing trade detection compatible.
			s.isLpPair[pair] = enabled;

			if (enabled) {
				s.pairAddress = pair;
			} else if (s.pairAddress == pair) {
				s.pairAddress = address(0);
			}

			emit AutomatedMarketMakerPairUpdated(pair, enabled);
		}

		function getWalletFlags(address account) external view override
			returns (
				bool feeExempt,
				bool exchangeWallet,
				bool excludedFromFee,
				bool excludedFromLimits,
				bool exemptFromLimits,
				bool automatedMarketMakerPair,
				bool authorizedMinter
			)
		{
			LibAppStorage.AppStorage storage s =
				LibAppStorage.diamondStorage();

			return (
				s.isFeeExempt[account],
				s.isExchangeWallet[account],
				s.isExcludedFromFee[account],
				s.isExcludedFromLimits[account],
				s.isExemptFromLimits[account],
				s.automatedMarketMakerPairs[account],
				s.isAuthorizedMinter[account]
			);
		}
	
	}	

 