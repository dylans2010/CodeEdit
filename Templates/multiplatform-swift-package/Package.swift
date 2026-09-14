// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{{PROJECT_NAME}}",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "{{PROJECT_NAME}}", targets: ["{{PROJECT_NAME}}"])
    ],
    targets: [
        .target(name: "{{PROJECT_NAME}}", dependencies: []),
        .testTarget(name: "{{PROJECT_NAME}}Tests", dependencies: ["{{PROJECT_NAME}}"])
    ]
)
