// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = { Package (
	name: $0,
	platforms: [.macOS (.v11)],
	products: [.executable (name: $0, targets: ["app"])],
	targets: [
		.target (name: "app", dependencies: ["lib", "ext"], path: "app", exclude: ["Info.plist"], linkerSettings: [.unsafeFlags (["-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist", "-Xlinker", "app/Info.plist"])]),
		.target (name: "lib", dependencies: ["ext"], path: "lib"),
		.target (name: "ext", path: "ext"),
	]
)} ("upwork-cos-gen");
