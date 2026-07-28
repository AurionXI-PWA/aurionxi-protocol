// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { LibDiamond } from ".././libraries/LibDiamond.sol";
import { LibCoreStorage } from ".././libraries/LibCoreStorage.sol";
import { ICoreDiamondCut } from "./interfaces/ICoreDiamondCut.sol";


/*=============================================================================
                            SECURITY & GOVERNANCE POLICY
==============================================================================

AurionXI is designed with a security-first architecture that prioritizes
long-term ecosystem sustainability, investor protection, and protocol stability.

The administrative controls implemented within the protocol are NOT intended
to provide arbitrary authority over user assets or market behavior. Their
sole purpose is to protect the protocol during exceptional situations and
ensure fair participation for all users.
 
--------------------------------------------------------------------------
BLACKLIST POLICY
--------------------------------------------------------------------------
The blacklist mechanism exists exclusively to protect the protocol against
malicious actors.
A wallet may only be blacklisted under exceptional circumstances such as:

• Smart contract exploits
• Flash-loan attacks
• Liquidity draining attempts
• Automated bot abuse
• Protocol manipulation
• Legally binding regulatory requirements (where applicable)

The blacklist MUST NOT be used to suppress legitimate investors,
restrict normal trading activity, or manipulate token price.

--------------------------------------------------------------------------
EMERGENCY MODE
--------------------------------------------------------------------------
Emergency Mode may be activated only when critical protocol security is at risk.
Examples include:

• Active security exploits
• Smart contract vulnerabilities
• Oracle failures
• Infrastructure failures
• Critical protocol malfunction
• Major attack on user funds

Emergency Mode is intended to provide temporary protection until the issue
is resolved.

--------------------------------------------------------------------------
PAUSE MECHANISM
--------------------------------------------------------------------------
Certain protocol operations may be temporarily paused during:

• Security investigations
• Emergency upgrades
• Critical bug fixes
• Active exploit mitigation
• Infrastructure maintenance

Normal operations should resume as soon as the protocol is considered safe.
--------------------------------------------------------------------------
GOVERNANCE PHILOSOPHY
--------------------------------------------------------------------------

Administrative permissions are implemented solely for protocol security,
operational continuity, and emergency response.

As the AurionXI ecosystem matures, governance responsibilities may gradually
transition toward decentralized governance mechanisms (DAO) where appropriate.

--------------------------------------------------------------------------
TRANSPARENCY COMMITMENT
--------------------------------------------------------------------------

AurionXI is committed to:

• Fair market participation
• Transparent protocol management
• Long-term ecosystem sustainability
• Responsible security practices
• Continuous protocol improvement

The ultimate objective of every administrative feature is to protect
users, strengthen protocol resilience, and support sustainable ecosystem growth.

=============================================================================*/
/*
Protocol : AurionXI
Version  : 1.0.0
Standard : EIP-2535 Diamond
Compiler : Solidity ^0.8.22
Network  : BNB Smart Chain
License  : MIT
*/

contract CoreDiamond {
	
    constructor(address owner, address coreDiamondCutFacet) payable {
        require(owner != address(0), "OWNER_ZERO");
		require(coreDiamondCutFacet != address(0), "CoreDiamondCutFacet required here");
		
		// Set Deployer as the owner
        LibDiamond.setContractOwner(owner);
		
		LibCoreStorage.CoreStorage storage cs = LibCoreStorage.coreStorage();
		 
		 // Bind CoreDiamond address in storage
		cs.coreDiamond = address(this);
		
	// ============================================================
	// IMMUTABLE CORE SELECTORS (ONE-TIME LOCK)
	// ============================================================
	
	cs.immutableSelectors[ICoreDiamondCut.diamondCut.selector] = true;
	cs.immutableSelectors[bytes4(keccak256("transferOwnership(address)"))] = true;
		
        //========= owner() selector immutable=========================
		cs.immutableSelectors[ bytes4(keccak256("owner()")) ] = true;
		
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = ICoreDiamondCut.diamondCut.selector;

        ICoreDiamondCut.FacetCut[] memory cut = new ICoreDiamondCut.FacetCut[](1);
        cut[0] = ICoreDiamondCut.FacetCut({
            facetAddress: coreDiamondCutFacet,
            action: ICoreDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        LibDiamond.diamondCut(_convertCut(cut), address(0), "");
    }
		
		// FALLBACK Function
    
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "CoreDiamond: Function not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 { revert(0, returndatasize()) }
                default { return(0, returndatasize()) }
        }
    }

    receive() external payable {
        revert("CORE_NO_ETH");
    }

    function _convertCut(ICoreDiamondCut.FacetCut[] memory _cut)
        internal
        pure
        returns (LibDiamond.FacetCut[] memory converted)
    {
        converted = new LibDiamond.FacetCut[](_cut.length);
        for (uint256 i = 0; i < _cut.length; i++) {
            converted[i] = LibDiamond.FacetCut({
                facetAddress: _cut[i].facetAddress,
                action: LibDiamond.FacetCutAction(uint8(_cut[i].action)),
                functionSelectors: _cut[i].functionSelectors
            });
        }
    }
}