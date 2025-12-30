// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VibeFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VibeFlow",
            targets: ["VibeFlow"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/google/generative-ai-swift", from: "0.5.0")
    ],
    targets: [
        .executableTarget(
            name: "VibeFlow",
            dependencies: [
                .product(name: "GoogleGenerativeAI", package: "generative-ai-swift")
            ],
            path: "Sources"
        )
    ]
)
