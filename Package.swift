// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "rtvi",
    platforms: [
        .macOS(.v12), .iOS(.v15)
    ],
    products: [
        .library(name: "rtvi", targets: ["rtvi"]),
    ],
    targets: [
        .target(
            name: "rtvi",
            path: "src"
        ),
    ]
)