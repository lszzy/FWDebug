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
            url: "https://github.com/lszzy/FWDebug/releases/download/6.0.0/FWDebug.xcframework.zip",
            checksum: "30da5a8a975e2d865a34b771e445aa34ee3e2adebdf5877286ea91294db879a4"
        )
    ]
)
