import PackageDescription

let package = Package(
    name: "cocoarobot",
	dependencies: [
		.Package(url: "https://github.com/ShaneQi/ZEGBot.git", majorVersion: 2),
		.Package(url:"https://github.com/PerfectlySoft/Perfect-SQLite.git", majorVersion: 2, minor: 0),
	]
)
