// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./ICoreDiamondCut.sol";

interface IUpgradeControlFacet {

    event CoreUpgradeScheduled(bytes32 hash, uint256 readyTime);
    event EmergencyUpgradeEnabled();
    event EmergencyUpgradeDisabled();
	event UpgradeStateReset();
	event CoreScheduledUpgradeExecuted(bytes32 upgradeHash, address childDiamond);
	
	
    function openWindow() external;
    function closeWindow() external;
    function isUpgradeWindow() external view returns (bool);
			
    function scheduleCoreUpgrade(
		ICoreDiamondCut.FacetCut[] calldata cut,
		address init,
		bytes calldata data,
		string calldata intent,
		uint256 hoursDelay,
		uint256 expiryHours
	) external;
	
	function enableEmergencyMode() external;
    function disableEmergencyMode() external;
	
    function resetUpgradeState() external;
}