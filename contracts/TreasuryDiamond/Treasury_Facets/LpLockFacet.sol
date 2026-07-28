// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibCoreStorage.sol";
import { LibDiamond } from "../../libraries/LibDiamond.sol";

import "../interfaces/ILpLockFacet.sol";

/*
|--------------------------------------------------------------------------
| LIQUIDITY MANAGEMENT
|--------------------------------------------------------------------------
| Liquidity operations support long-term market stability.
|
| Liquidity should only be managed in accordance with protocol governance
| and ecosystem requirements.
|--------------------------------------------------------------------------
*/

interface ICoreGuardianEmergencyRead {
    function isGuardianEmergencyApproved() external view returns (bool);
}

contract LpLockFacet is ILpLockFacet {
    using SafeERC20 for IERC20;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier nonReentrant() {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.reentrancyLock, "REENTRANCY");
        s.reentrancyLock = true;
        _;
        s.reentrancyLock = false;
    }

    function lockLp(
        address lpToken,
        uint256 amount,
        uint256 unlockTimestamp
    ) external override onlyOwner nonReentrant {
        _lockLpFrom(msg.sender, lpToken, amount, unlockTimestamp);
    }

    function lockLpFrom(
        address from,
        address lpToken,
        uint256 amount,
        uint256 unlockTimestamp
    ) external override onlyOwner nonReentrant {
        _lockLpFrom(from, lpToken, amount, unlockTimestamp);
    }

    function withdrawLockedLp(
        address lpToken,
        address to
    ) external override onlyOwner nonReentrant {
        require(lpToken != address(0), "LP_ZERO_ADDRESS");
        require(to != address(0), "TO_ZERO_ADDRESS");

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        LibAppStorage.Lock storage lpLock = s.lockedLp[lpToken];

        uint256 amount = lpLock.amount;
        require(amount > 0, "NO_LOCKED_LP");
        require(block.timestamp >= lpLock.unlockTimestamp, "LP_STILL_LOCKED");

        _requireGuardianEmergencyApproval();

        delete s.lockedLp[lpToken];

        IERC20(lpToken).safeTransfer(to, amount);

        emit LpWithdrawn(lpToken, to, amount);
    }

    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external override onlyOwner nonReentrant {
        require(token != address(0), "TOKEN_ZERO_ADDRESS");
        require(to != address(0), "TO_ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 lockedAmount = s.lockedLp[token].amount;
        uint256 rescuableAmount = balance > lockedAmount
            ? balance - lockedAmount
            : 0;

        require(amount <= rescuableAmount, "AMOUNT_EXCEEDS_RESCUABLE");

        _requireGuardianEmergencyApproval();

        IERC20(token).safeTransfer(to, amount);

        emit RescueExecuted(token, to, amount);
    }

    function rescueBNB(
        address payable to,
        uint256 amount
    ) external override onlyOwner nonReentrant {
        require(to != address(0), "TO_ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");
        require(address(this).balance >= amount, "INSUFFICIENT_BNB");

        _requireGuardianEmergencyApproval();

        (bool success, ) = to.call{value: amount}("");
        require(success, "BNB_TRANSFER_FAILED");

        emit RescueExecuted(address(0), to, amount);
    }

    function getLockedLp(
        address lpToken
    ) external view override returns (
        uint256 amount,
        uint256 unlockTimestamp
    ) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        LibAppStorage.Lock storage lpLock = s.lockedLp[lpToken];

        return (lpLock.amount, lpLock.unlockTimestamp);
    }

    function getLpLockStatus(
        address lpToken
    ) external view override returns (
        uint256 lockedAmount,
        uint256 unlockTimestamp,
        uint256 contractLpBalance,
        uint256 excessLpBalance,
        bool isLocked,
        bool canWithdraw
    ) {
        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        LibAppStorage.Lock storage lpLock = s.lockedLp[lpToken];

        lockedAmount = lpLock.amount;
        unlockTimestamp = lpLock.unlockTimestamp;
        contractLpBalance = IERC20(lpToken).balanceOf(address(this));

        excessLpBalance = contractLpBalance > lockedAmount
            ? contractLpBalance - lockedAmount
            : 0;

        isLocked = lockedAmount > 0 && block.timestamp < unlockTimestamp;
        canWithdraw = lockedAmount > 0 && block.timestamp >= unlockTimestamp;
    }

    function _lockLpFrom(
        address from,
        address lpToken,
        uint256 amount,
        uint256 unlockTimestamp
    ) internal {
        require(from != address(0), "FROM_ZERO_ADDRESS");
        require(lpToken != address(0), "LP_ZERO_ADDRESS");
        require(amount > 0, "ZERO_AMOUNT");
        require(unlockTimestamp > block.timestamp, "INVALID_UNLOCK_TIME");

        uint256 allowance = IERC20(lpToken).allowance(from, address(this));
        require(allowance >= amount, "LP_ALLOWANCE_TOO_LOW");

        LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
        LibAppStorage.Lock storage lpLock = s.lockedLp[lpToken];

        uint256 oldUnlockTimestamp = lpLock.unlockTimestamp;

        IERC20(lpToken).safeTransferFrom(from, address(this), amount);

        lpLock.amount += amount;

        if (unlockTimestamp > lpLock.unlockTimestamp) {
            lpLock.unlockTimestamp = unlockTimestamp;
        }

        emit LpLocked(lpToken, amount, lpLock.unlockTimestamp);
        emit LpLockedFrom(lpToken, from, amount, lpLock.unlockTimestamp);

        if (
            oldUnlockTimestamp != 0 &&
            lpLock.unlockTimestamp > oldUnlockTimestamp
        ) {
            emit LpLockExtended(
                lpToken,
                oldUnlockTimestamp,
                lpLock.unlockTimestamp
            );
        }
    }

    function _requireGuardianEmergencyApproval() internal view {
        address coreDiamond = _coreDiamond();

        require(
            ICoreGuardianEmergencyRead(coreDiamond).isGuardianEmergencyApproved(),
            "GUARDIAN_APPROVAL_REQUIRED"
        );
    }

    function _coreDiamond() internal view returns (address coreDiamond) {
        coreDiamond = LibCoreStorage.coreStorage().coreDiamond;
        require(coreDiamond != address(0), "CORE_NOT_SET");
    }

    receive() external payable {
        revert("LP_LOCK_FACET_NO_ETH");
    }
}