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
        .package(url: "https://github.com/FluidInference/FluidAudio.git", from: "0.12.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "LagunaWave",
            dependencies: [
                .product(name: "FluidAudio", package: "FluidAudio"),
                .product(name: "MLXLLM", package: "mlx-swift-lm")
            ]
        )
    ]
)
