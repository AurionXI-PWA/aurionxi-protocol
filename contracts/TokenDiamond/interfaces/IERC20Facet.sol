// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// @title ERC20 Interface
// @notice Standard interface for ERC20 tokens (OpenZeppelin v5.1.0)

//import "../interfaces/IARXIToken.sol";

// file name should this IERC20Facet because already have in openZeppline IERC20

interface IERC20Facet {

	event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    
	// =============================================================
    // ERC20 BASICS
    // =============================================================
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
	function maxSupply() external view returns (uint256);  
	function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);	
    function feeCollector() external view returns (address);
		
	function treasuryWallet() external view returns (address);
	function rewardDistributor() external view returns (address);
	function liquidityLocker() external view returns (address);
	function marketingWallet() external view returns (address);
	function burnWallet() external view returns (address);
	
	// =============================================================
    // APPROVE / TRANSFER
    // =============================================================
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}