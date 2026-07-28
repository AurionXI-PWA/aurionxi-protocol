// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "../../libraries/LibAppStorage.sol";
import "../interfaces/IERC20Facet.sol";

import "../../TradeDiamond/interfaces/ITradeFacet.sol";
import "../../TradeDiamond/interfaces/IAntiBot.sol";


contract ERC20Facet is IERC20Facet {
    
	// =============================================================
	//  ERC20-LIKE BASICS
	// =============================================================
	function name() external view returns (string memory) {
		return LibAppStorage.diamondStorage().name;
		}

	function symbol() external view returns (string memory) {
		return LibAppStorage.diamondStorage().symbol;
		}

	function decimals() external pure returns (uint8) {
		return 18;
		}

	function totalSupply() external view returns (uint256) {
		return LibAppStorage.diamondStorage().totalSupply;
		}
	
	function maxSupply() external view returns (uint256) {
        return LibAppStorage.diamondStorage().maxSupply;
		}
		
	function balanceOf(address account) public view returns (uint256) {
		return LibAppStorage.diamondStorage().balances[account];
		}

	function allowance(address owner, address spender) external view returns (uint256) {
		return LibAppStorage.diamondStorage().allowances[owner][spender];
		}
		
    function feeCollector() external view returns (address) {
        return LibAppStorage.diamondStorage().feeCollector;
		}
	
	function treasuryWallet() external view returns (address) {
        return LibAppStorage.diamondStorage().treasuryWallet;
		}
		
	function rewardDistributor() external view returns (address) {
        return LibAppStorage.diamondStorage().rewardDistributor;
		}
		
	function liquidityLocker() external view returns (address) {
        return LibAppStorage.diamondStorage().liquidityLocker;
		}
		
	function marketingWallet() external view returns (address) {
        return LibAppStorage.diamondStorage().marketingWallet;
		}
		
	function burnWallet() external view returns (address) {
        return LibAppStorage.diamondStorage().burnWallet;
		}
		
		
    // =============================================================
	//  APPROVE / TRANSFER
	// =============================================================
    function transfer(address to, uint256 amount) external returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		require(!s.paused, "TOKEN_PAUSED");
		_transfer(msg.sender, to, amount);
        return true;
		}

    function transferFrom(address from, address to, uint256 amount) 
		external returns (bool) {
        
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 currentAllowance = s.allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        if (currentAllowance != type(uint256).max) {
			s.allowances[from][msg.sender] =
				currentAllowance - amount;

			emit Approval(
				from,
				msg.sender,
				s.allowances[from][msg.sender]
			);
		}
        _transfer(from, to, amount);
        return true;
		
		}
	  
	function approve(address spender, uint256 amount) external returns (bool) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        
		 require(spender != address(0), "ZERO_ADDRESS");

        // Allowance race protection
        require(
            amount == 0 || s.allowances[msg.sender][spender] == 0,
            "RESET_ALLOWANCE_FIRST"
        );
			s.allowances[msg.sender][spender] = amount;
			emit Approval(msg.sender, spender, amount);
        
		return true;
		
		}
	// =============================================================
	//  INTERNAL TRANSFER LOGIC for updates after transfer
	// =============================================================
	function _transfer(address from, address to, uint256 amount) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		
		require(from != address(0), "ZERO_FROM");
        require(to != address(0), "ZERO_TO");
        require(amount > 0, "ZERO_AMOUNT");

        require(!s.paused, "TOKEN_PAUSED");
		
		//--------------------------------------------------
		//   1️⃣ TRADE VALIDATION (RULES ONLY)
		//-------------------------------------------------- 
		
		try ITradeFacet(address(this)).validateTrade(
			from,
			to,
			amount
		) {
		} catch Error(string memory reason) {
		
			revert(reason);
		
		} catch {
		
			revert("TRADE_VALIDATION_FAILED");
		}
		
		 //--------------------------------------------------
		// 2️⃣ BUY / SELL DETECTION
		//--------------------------------------------------

		bool isSell =
		(
			to == s.pairAddress ||
			s.isLpPair[to] ||
			s.isMarketPair[to]
		);

		bool isBuy =
		(
			from == s.pairAddress ||
			s.isLpPair[from] ||
			s.isMarketPair[from]
		);

		//--------------------------------------------------
		// 3️⃣ VOLUME ANALYTICS
		//--------------------------------------------------

		if (isBuy) {

			s.totalTradeVolume[to] += amount;
			s.totalBuyVolume[to] += amount;

		}

		if (isSell) {

			s.totalTradeVolume[from] += amount;
			s.totalSellVolume[from] += amount;

		}

			// AntiBot hook: enforce restriction only on real trader.
			// Buy  = monitor buyer (to)
			// Sell = monitor seller (from)
			// Wallet transfer = monitor both normal wallets
			if (s.antiBotActive) {
				if (isBuy) {
					IAntiBot(address(this)).monitorTrade(to);
				} else if (isSell) {
					IAntiBot(address(this)).monitorTrade(from);
				} else {
					IAntiBot(address(this)).monitorTrade(from);
					IAntiBot(address(this)).monitorTrade(to);
				}
			}
		}
	
	}
	
	 