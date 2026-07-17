// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CCUsageMenu",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CCUsageMenu", targets: ["CCUsageMenu"])
    ],
    targets: [
        .executableTarget(
            name: "CCUsageMenu",
            path: "Sources/CCUsageMenu"
        ),
        .testTarget(
            name: "CCUsageMenuTests",
            dependencies: ["CCUsageMenu"],
            path: "Tests/CCUsageMenuTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
