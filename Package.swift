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
            url: "https://github.com/lszzy/FWDebug/releases/download/5.5.0/FWDebug.xcframework.zip",
            checksum: "51646d068af2258bc49be70c764af09e3e5ff07cd8c926b66b2a60f444796efe"
        )
    ]
)
