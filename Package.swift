// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "FWDebugPackage",
    platforms: [
        .iOS("11.0")
    ],
    products: [
        .library(
            name: "FWDebugPackage",
            targets: ["FWDebugPackage"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FWDebugPackage",
            dependencies: [
                .target(name: "FWDebug"),
            ],
            path: "Package"
        ),
        .binaryTarget(
            name: "FWDebug",
            url: "https://github.com/lszzy/FWDebug/releases/download/5.3.0/FWDebug.xcframework.zip",
            checksum: "c2941ebe998c381bdacf50d635eeef5ab72edb8c3992d987525cd06cb23ae7d7"
        ),
    ]
)
