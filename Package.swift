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
            url: "https://github.com/lszzy/FWDebug/releases/download/5.3.0/FWDebug.xcframework.zip",
            checksum: "c2941ebe998c381bdacf50d635eeef5ab72edb8c3992d987525cd06cb23ae7d7"
        )
    ]
)
