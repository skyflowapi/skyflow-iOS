// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Skyflow",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Legacy vault SDK 1(v1 API contract).
        .library(
            name: "Skyflow",
            targets: ["Skyflow"]),
        // FlowVault SDK (v2 API contract). Module name is SkyflowFlowVaultIOS.
        .library(
            name: "Skyflow-flowvault-ios",
            targets: ["SkyflowFlowVaultIOS"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Shared, contract-agnostic core: UI elements, validations, styles,
        // container machinery, token/JWT handling, logging, errors, utils.
        .target(
            name: "SkyflowCore",
            dependencies: [],
            resources: [
                   .process("Resources")
                 ]
            ),
        // Legacy (v1) contract layer.
        .target(
            name: "Skyflow",
            dependencies: ["SkyflowCore"]
            ),
        // FlowVault (v2) contract layer.
        .target(
            name: "SkyflowFlowVaultIOS",
            dependencies: ["SkyflowCore"]
            ),
        .testTarget(
            name: "skyflow-iOS-collectTests",
            dependencies: ["SkyflowFlowVaultIOS", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-revealTests",
                    dependencies: ["SkyflowFlowVaultIOS", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-errorTests",
                    dependencies: ["SkyflowFlowVaultIOS", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-getByIdTests",
                        dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-elementTests",
                    dependencies: ["SkyflowFlowVaultIOS", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-utilTests",
                        dependencies: ["SkyflowFlowVaultIOS", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-legacyTests",
                        dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-scenarioTests",
                            dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-getTests",
                   dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-composableTests", dependencies: ["SkyflowFlowVaultIOS", "SkyflowCore"])
    ]
)
