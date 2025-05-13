// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "FWDebug",
        platforms: [
            .iOS(.v12)
        ],
    products: [
        .library(
            name: "FWDebug",
            targets: ["FWDebug"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "FWDebug",
            url: "https://github.com/lszzy/FWDebug/releases/download/6.0.2/FWDebug.xcframework.zip",
            checksum: "2102ce0fb3b58de4bb9b994c9a000bc6acd9ececdea46ae164938bde89bf0930"
        )
    ]
)
