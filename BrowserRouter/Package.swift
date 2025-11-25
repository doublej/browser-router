// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "BrowserRouter",
    platforms: [
        .macOS(.v26)
    ],
    targets: [
        .executableTarget(
            name: "BrowserRouter",
            path: "Sources/BrowserRouter"
        )
    ]
)
