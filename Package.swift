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
            checksum: "9e5b06907e54adf494754cb61f334e52029555bab8dc938a29521acf2293faa2"
        )
    ]
)
