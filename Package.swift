// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "cocoarobot",
	products: [
		.executable(name: "cocoarobot", targets: ["cocoarobot"])
	],
	dependencies: [
		.package(url: "https://github.com/shaneqi/ZEGBot.git", from: Version(4,2,7)),
	],
	targets: [
		.executableTarget(name: "cocoarobot", dependencies: ["ZEGBot"], path: "./Sources"),
        
	],
	swiftLanguageVersions: [.v5]
)
