// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SkillDumpster",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SkillDumpster", targets: ["SkillDumpster"]),
        .library(name: "SkillDumpsterCore", targets: ["SkillDumpsterCore"])
    ],
    targets: [
        .target(name: "SkillDumpsterCore"),
        .executableTarget(
            name: "SkillDumpster",
            dependencies: ["SkillDumpsterCore"]
        ),
        .testTarget(
            name: "SkillDumpsterCoreTests",
            dependencies: ["SkillDumpsterCore"]
        )
    ]
)
