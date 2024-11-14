// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KiwiScannerSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "KiwiScannerSDK",
            targets: ["KiwiScannerSDK"]),
    ],
    targets: [
        
        .target(
            name: "KiwiScannerSDK",
            dependencies: ["StandardCyborgFusion", "StandardCyborgUI"]
        ),
        
        .target(
            name: "StandardCyborgUIObjC",
            path: "Sources/StandardCyborgUIObjC",
            publicHeadersPath: "."
        ),
        
        .target(name: "StandardCyborgUI",
                dependencies: ["StandardCyborgUIObjC"],
                path: "Sources/StandardCyborgUI",
                resources: [
                    .process("Assets.xcassets")
                ]
        ),
        
//        .binaryTarget(
//            name: "StandardCyborgFusion",
//            path: "KiwiScannerSDK/lib/StandardCyborgFusion.xcframework"
//        ),
        .binaryTarget(name: "StandardCyborgFusion", url: "https://github.com/1agora/KiwiScannerSDK/releases/download/1.0.0/StandardCyborgFusion.xcframework.zip", checksum: "2f5dca4d4bf29fac8ebc0a1ff553a7324a3cbaaf522df902b0e01a2103814110")

    ]
)
