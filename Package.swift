import PackageDescription

let package = Package(
    name: "cocoarobot",
	dependencies: [
		.Package(url: "https://github.com/ShaneQi/ZEGBot.git", versions: Version(0,0,0)..<Version(10,0,0))
	]
)
