// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibDiamond.sol";
import "../../libraries/LibAppStorage.sol";
import "../interfaces/IARXITokenInit.sol";

contract ARXITokenInitFacet is IARXITokenInit
	{
	modifier onlyOwner() 
		{	LibDiamond.enforceIsContractOwner();
			_;
		}
	
	function initializeToken(
		string memory name_,
		string memory symbol_,
		uint256 totalSupply_,
		uint256 initialBuyTaxBps,
		uint256 initialSellTaxBps,
		address initialSupplyRecipient
	) external onlyOwner {

	LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		require(!s.initialized, "AurionXI: Already initialized");
		require(totalSupply_ > 0, "zero supply");
	require(initialBuyTaxBps <= 500 && initialSellTaxBps <= 1000, "tax too high");
			
		// Token details
		s.name = name_;
		s.symbol = symbol_;
		s.totalSupply = totalSupply_;
		s.owner = LibDiamond.contractOwner();
		s.balances[initialSupplyRecipient] = totalSupply_;

		s.buyTaxBps = initialBuyTaxBps;
		s.sellTaxBps = initialSellTaxBps;

		// Start paused until listing
		
		s.emergencyMode= true;
		s.paused = true;
		s.limitBaseSupply = totalSupply_;
		
		emit InitializedToken(name_, symbol_, totalSupply_);
	}
			
	function initializeWallets(
		address initialFeeCollector,
		address _treasuryWallet,
		address _rewardDistributor,
		address _liquidityLocker,
		address _marketingWallet,
		address _burnWallet
	) external onlyOwner {
	
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(!s.initialized, "Initialization locked");
		
		require(_treasuryWallet != address(0), "treasury zero");
		require(_rewardDistributor != address(0), "reward zero");
		require(_liquidityLocker != address(0), "liquidity zero");
		require(_marketingWallet != address(0), "marketing zero");
		require(initialFeeCollector != address(0), "fee collector zero");
		s.feeCollector = initialFeeCollector;
			
		// Wallets
		s.treasuryWallet = _treasuryWallet;
		s.rewardDistributor = _rewardDistributor;
		s.liquidityLocker = _liquidityLocker;
		s.marketingWallet = _marketingWallet;
		s.burnWallet = 		_burnWallet == address(0)
			? address(0x000000000000000000000000000000000000dEaD)
			: _burnWallet;
		s.owner = LibDiamond.contractOwner();

			// mark fee-exempt addresses
			s.isFeeExempt[msg.sender] 			= true;   // deployer/initializer
			s.isFeeExempt[s.owner]	          = true; // Diamond owner
			s.isFeeExempt[s.feeCollector]      = true; // tax collector
			s.isFeeExempt[s.treasuryWallet]    = true; // treasury reserve
			s.isFeeExempt[s.rewardDistributor] = true; // reward sender
			s.isFeeExempt[s.liquidityLocker]   = true; // LP lock
			s.isFeeExempt[s.marketingWallet]   = true; // marketing
			s.isFeeExempt[s.burnWallet]        = true; // dead wallet
		}

	//======= MAX_SUPPLY Function-----------------
	
	function tokenMaxSupply(uint256 _maxSupply) external onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
		require(!s.initialized, "Initialization locked");
		require(s.totalSupply > 0, "Token not initialized");
		require(_maxSupply > 0, "AurionXI: Invalid max supply");
		require(_maxSupply >= s.totalSupply, "Max supply < total supply");

		s.maxSupply = _maxSupply;
		
		emit MaxSupplyToken(_maxSupply);
		}
		
	function lockInitialization() external onlyOwner {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(!s.initialized, "Already locked");

		require(s.totalSupply > 0, "Token not initialized");
		require(s.maxSupply > 0, "Max supply missing");
		require(s.feeCollector != address(0), "Wallets missing");

		s.initialized = true;		//AppStorage

		emit InitializationLocked(s.owner);
	}	
}

 