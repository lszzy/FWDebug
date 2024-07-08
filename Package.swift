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
            url: "https://github.com/lszzy/FWDebug/releases/download/5.4.1/FWDebug.xcframework.zip",
            checksum: "7737a1f3c4cd9bf9756df89df33577813ddedcda24877ce8a583645a64b03b6d"
        )
    ]
)
