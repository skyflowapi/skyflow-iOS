// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Skyflow",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // PDB vault SDK
        .library(
            name: "Skyflow",
            targets: ["Skyflow"]),
        // FlowVault SDK
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
            path: "SkyflowCore/Sources",
            resources: [
                   .process("Resources")
                 ]
            ),
        // Legacy (v1) contract layer.
        .target(
            name: "Skyflow",
            dependencies: ["SkyflowCore"],
            path: "Skyflow/Sources"
            ),
        // FlowVault (v2) contract layer.
        .target(
            name: "SkyflowFlowVault",
            dependencies: ["SkyflowCore"],
            path: "SkyflowFlowVault/Sources"
            ),
        // Tests for the legacy (v1) SDK live under Skyflow/Tests/,
        // FlowVault (v2) SDK tests under SkyflowFlowVault/Tests/.
        .testTarget(
            name: "skyflow-iOS-collectTests",
            dependencies: ["SkyflowFlowVault", "SkyflowCore"],
            path: "SkyflowFlowVault/Tests/skyflow-iOS-collectTests"),
        .testTarget(name: "skyflow-iOS-revealTests",
                    dependencies: ["SkyflowFlowVault", "SkyflowCore"],
                    path: "SkyflowFlowVault/Tests/skyflow-iOS-revealTests"),
        .testTarget(name: "skyflow-iOS-errorTests",
                    dependencies: ["SkyflowFlowVault", "SkyflowCore"],
                    path: "SkyflowFlowVault/Tests/skyflow-iOS-errorTests"),
        .testTarget(name: "skyflow-iOS-getByIdTests",
                        dependencies: ["Skyflow", "SkyflowCore"],
                        path: "Skyflow/Tests/skyflow-iOS-getByIdTests"),
        .testTarget(name: "skyflow-iOS-elementTests",
                    dependencies: ["SkyflowFlowVault", "SkyflowCore"],
                    path: "SkyflowFlowVault/Tests/skyflow-iOS-elementTests"),
        .testTarget(name: "skyflow-iOS-utilTests",
                        dependencies: ["SkyflowFlowVault", "SkyflowCore"],
                        path: "SkyflowFlowVault/Tests/skyflow-iOS-utilTests"),
        .testTarget(name: "skyflow-iOS-legacyTests",
                        dependencies: ["Skyflow", "SkyflowCore"],
                        path: "Skyflow/Tests/skyflow-iOS-legacyTests"),
        .testTarget(name: "skyflow-iOS-scenarioTests",
                            dependencies: ["Skyflow", "SkyflowCore"],
                            path: "Skyflow/Tests/skyflow-iOS-scenarioTests"),
        .testTarget(name: "skyflow-iOS-getTests",
                   dependencies: ["Skyflow", "SkyflowCore"],
                   path: "Skyflow/Tests/skyflow-iOS-getTests"),
        .testTarget(name: "skyflow-iOS-composableTests",
                    dependencies: ["SkyflowFlowVault", "SkyflowCore"],
                    path: "SkyflowFlowVault/Tests/skyflow-iOS-composableTests")
    ]
)
