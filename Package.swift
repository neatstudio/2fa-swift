// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TwoFA",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "2fa", targets: ["TwoFA"]),
        .executable(name: "TwoFAVerify", targets: ["TwoFAVerify"]),
        .library(name: "TwoFACore", targets: ["TwoFACore"])
    ],
    targets: [
        .target(
            name: "TwoFACore",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CryptoKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "TwoFA",
            dependencies: ["TwoFACore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .executableTarget(
            name: "TwoFAVerify",
            dependencies: ["TwoFACore"]
        )
    ]
)
