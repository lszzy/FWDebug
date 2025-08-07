// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FWDebug",
        platforms: [
            .iOS(.v13)
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
            url: "https://github.com/lszzy/FWDebug/releases/download/6.1.0/FWDebug.xcframework.zip",
            checksum: "11139ca553b44d2d28b4df202ab747c5b5d654bb25ff5011072a879b31293cfd"
        )
    ]
)
