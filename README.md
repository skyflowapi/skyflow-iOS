# skyflow-iOS

Skyflow's iOS SDKs let you securely collect, tokenize, and display sensitive data in your mobile app without exposing your front-end infrastructure to sensitive data.

[![CI](https://img.shields.io/static/v1?label=CI&message=passing&color=green?style=plastic&logo=github)](https://github.com/skyflowapi/skyflow-ios/actions)
[![GitHub release](https://img.shields.io/github/v/release/skyflowapi/skyflow-ios.svg)](https://github.com/skyflowapi/skyflow-ios/releases)
[![License](https://img.shields.io/github/license/skyflowapi/skyflow-ios)](https://github.com/skyflowapi/skyflow-ios/blob/main/LICENSE)

This repository publishes two SDKs from a shared codebase. Pick the one that matches your vault type:

| SDK | Vault type | Install (CocoaPods / SPM product) | Import | Documentation |
|-----|------------|-----------------------------------|--------|---------------|
| **Skyflow** | PDB vault (v1 API) | `pod 'Skyflow'` / `Skyflow` | `import Skyflow` | [Skyflow/README.md](Skyflow/README.md) |
| **SkyflowFlowVault** | Flow vault (v2 API, beta) | `pod 'SkyflowFlowVault'` / `SkyflowFlowVault` | `import SkyflowFlowVault` | [SkyflowFlowVault/README.md](SkyflowFlowVault/README.md) |

Not sure which one you need? If you are an existing Skyflow iOS customer, stay on **Skyflow** — it is fully backward compatible. **SkyflowFlowVault** is for Flow vaults; if you are moving from a PDB vault, follow its [Upgrading from PDB to FlowDB](SkyflowFlowVault/README.md#upgrading-from-pdb-to-flowdb) migration guide.

## Repository layout

- `Skyflow/` — Skyflow SDK([README.md](Skyflow/README.md))
- `SkyflowFlowVault/` — SkyflowFlowVault SDK([README.md](SkyflowFlowVault/README.md))
- `SkyflowCore/` — shared internal module compiled into both SDKs (not installable on its own)
- `<SDK>/Samples/` — sample apps for each SDK

## Requirements

- iOS 13+
- Xcode 15+ (Swift 5.9 toolchain) to build
