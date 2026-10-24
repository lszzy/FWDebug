// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FWDebug",
        platforms: [
            .iOS(.v15)
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
            url: "https://github.com/lszzy/FWDebug/releases/download/6.2.0/FWDebug.xcframework.zip",
            checksum: "22372905f3b46d8de49e59e024d9721208dcd4614e75bf4e1e67ee9b15f07f1c"
        )
    ]
)
