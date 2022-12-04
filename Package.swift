// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "cocoarobot",
    platforms: [
        .macOS(.v10_15)
    ],
	products: [
		.executable(name: "cocoarobot", targets: ["cocoarobot"])
	],
	dependencies: [
		.package(url: "https://github.com/shaneqi/ZEGBot.git", from: "4.2.8"),
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0")
	],
	targets: [
        .executableTarget(name: "cocoarobot", dependencies: [
            .product(name: "ZEGBot", package: "ZEGBot"),
            .product(name: "MySQLNIO", package: "mysql-nio")
        ], path: "./Sources"),
        
	],
	swiftLanguageVersions: [.v5]
)
