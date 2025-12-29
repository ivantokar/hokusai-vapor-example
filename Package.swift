// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "HokusaiVaporExample",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "HokusaiVaporExample", targets: ["HokusaiVaporExample"])
    ],
    dependencies: [
        // A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // An expressive, performant, and extensible templating language built for Swift.
        .package(url: "https://github.com/vapor/leaf.git", from: "4.3.0"),
        // Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        // Hokusai Vapor integration
        .package(url: "https://github.com/ivantokar/hokusai-vapor.git", from: "0.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "HokusaiVaporExample",
            dependencies: [
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "HokusaiVapor", package: "hokusai-vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            swiftSettings: swiftSettings
        )
    ]
)

var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] }
