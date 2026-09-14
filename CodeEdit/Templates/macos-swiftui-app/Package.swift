// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "{{PROJECT_NAME}}",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "{{PROJECT_NAME}}", targets: ["{{PROJECT_NAME}}"])
    ],
    targets: [
        .executableTarget(name: "{{PROJECT_NAME}}", path: "Sources")
    ]
)
