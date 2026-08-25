// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Skyflow",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Skyflow SDK
        .library(
            name: "Skyflow",
            targets: ["Skyflow"]),
        // SkyflowFlowVault SDK
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
        .target(
            name: "Skyflow",
            dependencies: ["SkyflowCore"],
            path: "Skyflow/Sources"
            ),
        .target(
            name: "SkyflowFlowVault",
            dependencies: ["SkyflowCore"],
            path: "SkyflowFlowVault/Sources"
            ),
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
                    path: "SkyflowFlowVault/Tests/skyflow-iOS-composableTests"),
        // Dual-SDK coexistence tests: import both products side by side,
        // public API only, the way an app installing both pods would.
        .testTarget(name: "skyflow-iOS-coexistenceTests",
                    dependencies: ["Skyflow", "SkyflowFlowVault"],
                    path: "Tests/skyflow-iOS-coexistenceTests"),
        // Shared-core logic tests: depend only on SkyflowCore, so core
        // regressions surface here independently of either SDK.
        .testTarget(name: "skyflow-iOS-coreTests",
                    dependencies: ["SkyflowCore"],
                    path: "SkyflowCore/Tests/skyflow-iOS-coreTests")
    ]
)
