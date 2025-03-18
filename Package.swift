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
            url: "https://github.com/lszzy/FWDebug/releases/download/6.0.1/FWDebug.xcframework.zip",
            checksum: "389c8e21199665400b18006baf2eb89f45e7cfb55ca40b75b3010d97fc0987d4"
        )
    ]
)
