// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Skyflow",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // PDB vault SDK 1(v1 API contract).
        .library(
            name: "Skyflow",
            targets: ["Skyflow"]),
        // FlowVault SDK (v2 API contract).
        .library(
            name: "SkyflowFlowVault",
            targets: ["SkyflowFlowVault"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
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
            name: "SkyflowFlowVault",
            dependencies: ["SkyflowCore"]
            ),
        .testTarget(
            name: "skyflow-iOS-collectTests",
            dependencies: ["SkyflowFlowVault", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-revealTests",
                    dependencies: ["SkyflowFlowVault", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-errorTests",
                    dependencies: ["SkyflowFlowVault", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-getByIdTests",
                        dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-elementTests",
                    dependencies: ["SkyflowFlowVault", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-utilTests",
                        dependencies: ["SkyflowFlowVault", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-legacyTests",
                        dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-scenarioTests",
                            dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-getTests",
                   dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-composableTests", dependencies: ["SkyflowFlowVault", "SkyflowCore"])
    ]
)
