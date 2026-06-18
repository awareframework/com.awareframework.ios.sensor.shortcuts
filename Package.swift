// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "com.awareframework.ios.sensor.shortcuts",
    platforms: [.iOS(.v14), .macOS(.v13)],
    products: [
        .library(
            name: "com.awareframework.ios.sensor.shortcuts",
            targets: [
                "com.awareframework.ios.sensor.shortcuts"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/awareframework/com.awareframework.ios.core.git", from: "1.3.0")
    ],
    targets: [
        .target(
            name: "com.awareframework.ios.sensor.shortcuts",
            dependencies: [
                .product(name: "com.awareframework.ios.core", package: "com.awareframework.ios.core")
            ],
            path: "Sources/com.awareframework.ios.sensor.shortcuts"
        ),
        .testTarget(
            name: "com.awareframework.ios.sensor.shortcutsTests",
            dependencies: [
                .target(name: "com.awareframework.ios.sensor.shortcuts")
            ],
            path: "Tests/com.awareframework.ios.sensor.shortcutsTests"
        )
    ],
    swiftLanguageModes: [.v5]
)
