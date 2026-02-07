// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LagunaWave",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LagunaWave", targets: ["LagunaWave"])
    ],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.12.0")
    ],
    targets: [
        .executableTarget(
            name: "LagunaWave",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio")
            ]
        )
    ]
)
