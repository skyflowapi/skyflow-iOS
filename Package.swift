// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Skyflow",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Skyflow",
            targets: ["Skyflow"]),
        .library(
            name: "SkyflowFlowVault",
            targets: ["SkyflowFlowVault"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SkyflowCore",
            dependencies: [],
            resources: [
                   .process("Resources")
                 ]
            ),
        .target(
            name: "Skyflow",
            dependencies: ["SkyflowCore"]),
        .target(
            name: "SkyflowFlowVault",
            dependencies: ["SkyflowCore"]),
        .testTarget(
            name: "skyflow-iOS-collectTests",
            dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-revealTests",
                    dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-errorTests",
                    dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-getByIdTests",
                        dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-elementTests",
                    dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-utilTests",
                        dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-scenarioTests",
                            dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-getTests",
                   dependencies: ["Skyflow", "SkyflowCore"]),
        .testTarget(name: "skyflow-iOS-composableTests", dependencies: ["Skyflow", "SkyflowCore"])
    ]
)
