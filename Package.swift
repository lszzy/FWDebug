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
            url: "https://github.com/lszzy/FWDebug/releases/download/5.3.1/FWDebug.xcframework.zip",
            checksum: "8e7d3376512f0d593394d397d79309670ca8a4715e6c94518d74a4e17496ae4d"
        )
    ]
)
