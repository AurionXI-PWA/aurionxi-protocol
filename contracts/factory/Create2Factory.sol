// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Create2Factory is Ownable {

    event Deployed(
        address indexed child,
        bytes32 indexed salt,
        bytes32 bytecodeHash
    );

    constructor(address coreDiamond) Ownable(coreDiamond) {
        require(coreDiamond != address(0), "INVALID_OWNER");
    }

    // ============================================================
    // DEPLOY CHILD DIAMOND USING CREATE2
    // ============================================================

    function deployChildDiamond(
        bytes memory bytecode,
        bytes32 salt
    )
        external
        onlyOwner
        returns (address child)
    {
        require(bytecode.length != 0, "BYTECODE_EMPTY");
        address predicted = computeAddress(salt, bytecode);
        require(predicted.code.length == 0, "ALREADY_DEPLOYED");

        assembly {
            child := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                salt
            )

            if iszero(extcodesize(child)) {
                revert(0, 0)
            }
        }

        emit Deployed(child, salt, keccak256(bytecode));
    }

    // ============================================================
    // COMPUTE CREATE2 ADDRESS
    // ============================================================

    function computeAddress(
        bytes32 salt,
        bytes memory bytecode
    )
        public
        view
        returns (address predicted)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(bytecode)
            )
        );

        predicted = address(uint160(uint256(hash)));
    }
}