// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "cocoarobot",
	products: [
		.executable(name: "cocoarobot", targets: ["cocoarobot"])
	],
	dependencies: [
		.package(url: "https://github.com/shaneqi/ZEGBot.git", .branch("cocoarobot")),
		.package(url: "https://github.com/PerfectlySoft/Perfect-MySQL.git", from: Version(3, 0, 0))
	],
	targets: [
		.target(name: "cocoarobot", dependencies: ["ZEGBot", "PerfectMySQL"], path: "./Sources")
	],
	swiftLanguageVersions: [.v4_2]
)
