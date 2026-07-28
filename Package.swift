// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LookAway",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LookAwayCore",
            targets: ["LookAwayCore"]
        ),
        .executable(
            name: "LookAway",
            targets: ["LookAway"]
        ),
        .executable(
            name: "LookAwayCoreChecks",
            targets: ["LookAwayCoreChecks"]
        )
    ],
    targets: [
        .target(
            name: "LookAwayCore"
        ),
        .executableTarget(
            name: "LookAway",
            dependencies: ["LookAwayCore"],
            path: "Sources/LookAwayApp"
        ),
        .executableTarget(
            name: "LookAwayCoreChecks",
            dependencies: ["LookAwayCore"],
            path: "Tests/LookAwayCoreChecks"
        )
    ]
)
