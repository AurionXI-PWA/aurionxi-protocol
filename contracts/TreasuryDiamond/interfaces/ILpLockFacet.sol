// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

interface ILpLockFacet {
    event LpLocked(
        address indexed lpToken,
        uint256 amount,
        uint256 unlockTimestamp
    );

    event LpLockedFrom(
        address indexed lpToken,
        address indexed from,
        uint256 amount,
        uint256 unlockTimestamp
    );

    event LpLockExtended(
        address indexed lpToken,
        uint256 oldUnlockTimestamp,
        uint256 newUnlockTimestamp
    );

    event LpWithdrawn(
        address indexed lpToken,
        address indexed to,
        uint256 amount
    );

    event RescueExecuted(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    function lockLp(
        address lpToken,
        uint256 amount,
        uint256 unlockTimestamp
    ) external;

    function lockLpFrom(
        address from,
        address lpToken,
        uint256 amount,
        uint256 unlockTimestamp
    ) external;

    function withdrawLockedLp(
        address lpToken,
        address to
    ) external;

    function rescueERC20(
        address token,
        address to,
        uint256 amount
    ) external;

    function rescueBNB(
        address payable to,
        uint256 amount
    ) external;

    function getLockedLp(
        address lpToken
    ) external view returns (
        uint256 amount,
        uint256 unlockTimestamp
    );

    function getLpLockStatus(
        address lpToken
    ) external view returns (
        uint256 lockedAmount,
        uint256 unlockTimestamp,
        uint256 contractLpBalance,
        uint256 excessLpBalance,
        bool isLocked,
        bool canWithdraw
    );
}