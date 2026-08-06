---
Document ID     : DOC-010
Title           : Developer Guide
Category        : Developer
Classification  : Public
Version         : Documentation v1.0
Status          : Stable
Audience        : Developers, Contributors, Protocol Engineers
Maintainer      : AurionXI Protocol Engineering
Last Updated    : 2026
Related Docs    : DOC-001, DOC-002, DOC-011
---
## Quick Facts

Purpose          : Introduce developers to the engineering workflow and development practices

Implementation   : Production

Architecture     : AurionXI Multi-Diamond Protocol (EIP-2535)

Document Type    : Developer Documentation

Component Type   : Developer Guide

Lifecycle Stage  : Development

Status           : Stable
# AurionXI Multi-Diamond Protocol

# Developer Guide

Version

Documentation v1.0

---

## Document Purpose

This guide introduces developers to the engineering philosophy, repository organization, development workflow, and contribution practices used throughout the AurionXI Multi-Diamond Protocol.

Rather than serving as a Solidity tutorial, this guide explains how the project is organized and how developers are expected to work within the existing architecture.

## Intended Audience

This guide is intended for:

- Smart Contract Developers
- Blockchain Engineers
- Security Researchers
- Contributors
- Auditors
- Protocol Integrators

## Before You Start

Developers are encouraged to read the documentation in the following order:

1. Documentation Overview

2. Architecture

3. Protocol Components

4. Deployment Methodology

5. Verification Workflow

6. Operational Readiness

Understanding the architectural principles before modifying the codebase is strongly recommended.

## Engineering Philosophy

Development within AurionXI follows engineering principles rather than feature-first implementation.

Developers should understand the architectural responsibility of a protocol domain before introducing new functionality.

The project values maintainability, explicit responsibility boundaries, reproducibility, and engineering transparency.

## Repository Organization

The repository is organized according to engineering domains rather than feature collections.

Representative directories include:

- contracts/

- facets/

- interfaces/

- libraries/

- storage/

- scripts/

- test/

- docs/

Each directory has a specific engineering responsibility within the protocol.

## Coding Principles

Developers should follow these principles:

• Preserve modularity

• Avoid unnecessary coupling

• Keep domain responsibilities explicit

• Prefer reusable infrastructure

• Document architectural decisions

• Maintain backward compatibility whenever practical

## Upgrade Philosophy

Protocol upgrades should preserve architectural consistency.

Developers are encouraged to extend existing protocol domains rather than introducing unnecessary complexity.

Upgrades should be accompanied by appropriate testing, deployment validation, and documentation updates.

## Documentation Requirements

Engineering documentation is considered part of the implementation.

Major architectural changes should be reflected in the relevant documentation before they are considered complete.

Documentation and implementation are expected to evolve together.

## Contribution Expectations

Contributors are encouraged to include:

• Engineering rationale

• Testing summary

• Documentation updates

• Upgrade considerations

• Backward compatibility notes

Engineering quality is evaluated together with implementation quality.

## Developer Checklist

Before submitting changes:

✓ Architecture reviewed

✓ Domain responsibility confirmed

✓ Tests completed

✓ Documentation updated

✓ Deployment considerations reviewed

✓ Upgrade impact evaluated

## Related Documents

Architecture

Protocol Components

Deployment Methodology

Verification Workflow

Operational Readiness

BatchExecutor

CREATE2

Upgrade Workflow


