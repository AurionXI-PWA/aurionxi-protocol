// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface IGovernanceFacet {

    event UpgradeProposed(
        bytes32 indexed upgradeHash,
        bytes32 indexed intentHash,
        string intent,
        uint256 readyTime,
        uint256 expiryTime,
        uint256 nonce
    );

    event ProposalCancelled(bytes32 indexed upgradeHash);
	event DAOSecurityFlagUpdated(string flagName, bool status);	
	
    function setDAOEnabled(bool status) external;
    		
    function proposeUpgradeHash(
        bytes32 upgradeHash,
        bytes4[] calldata selectors,
        string calldata intent,
        uint256 delayHours,
        uint256 expiryHours
    ) external;
	
	function cancelProposal() external;
	/*
	function proposeChildUpgradeHash(
		address child,
		bytes32 upgradeHash,
		bytes4[] calldata selectors,
		string calldata intent,
		uint256 delayHours,
		uint256 expiryHours
	) external;
	
	function cancelChildProposal(address child) external;
	
	*/
}