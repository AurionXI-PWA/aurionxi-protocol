// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from "../../libraries/LibDiamond.sol";

import { LibCoreStorage } from "../../libraries/LibCoreStorage.sol";
import { IERC165Facet } from "../interfaces/IERC165Facet.sol";

 
contract ERC165Facet is IERC165Facet {
	
	modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
	}
    
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return LibCoreStorage.coreStorage().supportedInterfaces[interfaceId];
    }

    function registerInterface(bytes4 interfaceId) external onlyOwner {
        // onlyOwner recommended
        LibCoreStorage.coreStorage().supportedInterfaces[interfaceId] = true;
    }

    function removeInterface(bytes4 interfaceId) external onlyOwner {
        // onlyOwner recommended
        LibCoreStorage.coreStorage().supportedInterfaces[interfaceId] = false;
    }
}