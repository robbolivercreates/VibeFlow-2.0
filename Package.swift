// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoxAiGo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VoxAiGo",
            targets: ["VoxAiGo"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "VoxAiGo",
            dependencies: [
                .product(name: "WhisperKit", package: "WhisperKit"),
            ],
            path: "Sources"
        )
    ]
)
