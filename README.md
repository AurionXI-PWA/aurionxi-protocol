# AurionXI Multi-Diamond Protocol

Production-grade modular blockchain infrastructure built on the EIP-2535 Diamond Standard.

AurionXI is a production-grade blockchain infrastructure project built around a modular Multi-Diamond architecture. The system separates protocol responsibilities into independent domains while maintaining coordinated governance through a unified CoreDiamond.

## Project Status

| Item | Status |
|------|--------|
| Development | Active |
| Network | BNB Smart Chain Mainnet |
| Protocol Status | Production |
| Architecture | Multi-Diamond (EIP-2535) |
| Documentation | Public |
| Repository | Active |

## Highlights

- Production deployment on BNB Smart Chain
- Multi-Diamond architecture using EIP-2535
- CREATE2 deterministic deployment
- BatchExecutor administrative workflow
- Modular Treasury, Trade, Token, Analytics, and AI domains
- Progressive security architecture
- Multi-signature governance transition design
- Public engineering documentation

## Technology Stack

| Component | Technology |
|-----------|------------|
| Blockchain | BNB Smart Chain |
| Standard | EIP-2535 Diamond |
| Language | Solidity 0.8.22 |
| Framework | Hardhat |
| Upgrade Model | Diamond Cut |
| Deployment | CREATE2 + BatchExecutor |
| License | MIT |

## Protocol Architecture

AurionXI follows a layered Multi-Diamond architecture. Each Diamond owns a specific protocol domain and is coordinated by CoreDiamond.

| Component | Responsibility |
|-----------|----------------|
| CoreDiamond | Protocol coordination, governance, security, upgrades |
| TreasuryDiamond | Treasury management and future LP-lock infrastructure |
| TradeDiamond | Trading rules, retail/institutional controls, anti-bot and tax policy |
| TokenDiamond | ARXI token lifecycle, fees, vesting, reads, recovery |
| AnalyticsDiamond | Analytics, reporting, market snapshots, wallet flow data |
| AIDiamond | AI-ready recommendations, reports, panic advice, tax suggestions |

## Mainnet Deployment

AurionXI has been deployed on BNB Smart Chain Mainnet using a structured workflow covering deployment, verification, operational validation, and readiness checks.

| Component | Mainnet Address |
|-----------|-----------------|
| CoreDiamond | `0xd9886FEEb82DF74737B7Dede86E3024A31637297` |
| TokenDiamond | `0x6fFEC4860325f8bfB3F000354708A7d0caE4b250` |
| TradeDiamond | `0xF96c4F5EB539c8ab27469D35cc75eAAb98abFECF` |
| TreasuryDiamond | `0x06BaBd1D1a24dBe7a9E93160dDd4Ae9bCC06893a` |
| AnalyticsDiamond | `0xC7F819626E03c669c54d3eD9F122d49Ccfab455e` |
| AIDiamond | `0xF42C30aB84fe2df2b9A27569d4BC019b0244eE0a` |
| SBT | `0x2f4d81fc66a647627D8901E2e626671BDa55F819` |
| CREATE2 Factory | `0x8BFfFAF85eA71a2FBB58e30105D50903f14d492a` |

Deployment and verification artifacts are available in `deployments/`.

## Repository Structure

```text
aurionxi-protocol/
|-- contracts/       Smart contracts, facets, interfaces, and libraries
|-- docs/            Engineering documentation
|-- deployments/     Public deployment and verification artifacts
|-- README.md
|-- SECURITY.md
|-- CONTRIBUTING.md
|-- CODE_OF_CONDUCT.md
|-- CHANGELOG.md
```

## Public Transparency Notice

This repository is published for transparency, community review, and audit review. It includes Solidity source code, interfaces, libraries, documentation, and public deployment artifacts.

This public repository does not include private environment files, wallet keys, internal operational logs, or full private deployment automation scripts.

## Quick Start

Clone the repository:

```bash
git clone https://github.com/AurionXI-PWA/aurionxi-protocol.git
cd aurionxi-protocol
```

Install dependencies:

```bash
npm install
```

Compile contracts:

```bash
npx hardhat compile
```

## Engineering Documentation

The documentation in `docs/` covers architecture, deployment methodology, verification workflow, operational readiness, governance, BatchExecutor usage, CREATE2 deployment strategy, and testing methodology.

## Security

Security issues should be reported responsibly. Please avoid public disclosure until the issue has been reviewed and addressed.

See `SECURITY.md` for details.

## License

This repository is released under the MIT License.