# AurionXI Enterprise Treasury  
### Hybrid UUPS Upgradeable Treasury + BSC Router Adapter + ARXIToken

This repository contains the **official smart contract implementation** for the AurionXI Enterprise Treasury using  architecture:

- **TreasuryUpgradeSafe (UUPS Upgradeable)**
- **BscRouterAdapter (Concrete PancakeSwap V2 Adapter)**
- **ARXI Token**
- **Full Deployment Scripts**
- **Production Hardhat Configuration**

---

## 📁 Repository Structure

contracts/
│
├─ adapters/
│ ├─ RouterAdapterBase.sol
│ └─ BscRouterAdapter.sol
│
├─ treasury/
│ └─ TreasuryUpgradeSafe.sol
│
├─ ARXIToken.sol
│
scripts/
│ ├─ deploy_token.js
│ ├─ deploy_treasury.js
│ ├─ deploy_adapter.js
│ └─ wire_treasury.js
│
hardhat.config.js
package.json
README.md