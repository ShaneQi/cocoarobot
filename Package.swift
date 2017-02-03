import PackageDescription

let package = Package(
    name: "cocoarobot",
	dependencies: [
		.Package(url: "https://github.com/ShaneQi/ZEGBot.git", versions: Version(0,0,0)..<Version(10,0,0)),
		.Package(url:"https://github.com/PerfectlySoft/Perfect-SQLite.git", majorVersion: 2, minor: 0),
	]
)
