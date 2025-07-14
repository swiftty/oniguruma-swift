// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "oniguruma-swift",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "COniguruma",
            targets: ["COniguruma"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "COniguruma",
            exclude: [
                "src/unicode_egcb_data.c",
                "src/unicode_wb_data.c",
                "src/unicode_property_data.c",
                "src/unicode_fold_data.c",
            ],
            cSettings: [
                .headerSearchPath("src")
            ]
        ),
        .testTarget(
            name: "COnigurumaTests",
            dependencies: [
                "COniguruma"
            ]
        )
    ]
)
