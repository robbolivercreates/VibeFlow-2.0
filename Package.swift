// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoxAiGo",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VoxAiGo",
            targets: ["VoxAiGo"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VoxAiGo",
            dependencies: [],
            path: "Sources"
        )
    ]
)
