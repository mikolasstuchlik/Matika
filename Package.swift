// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Matika",
    dependencies: [
        .package(name: "gir2swift", url: "https://github.com/mikolasstuchlik/gir2swift.git", .branch("master")),
        .package(name: "Gtk", url: "https://github.com/mikolasstuchlik/SwiftGtk.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "Matika",
            dependencies: ["Gtk"])
    ]
)
