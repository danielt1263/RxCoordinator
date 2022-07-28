// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RxCoordinator",
    products: [
        .library(
            name: "RxCoordinator",
            targets: ["RxCoordinator"]),
    ],
    dependencies: [
		.package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0")),
		.package(url: "https://github.com/danielt1263/RxResource.git", .upToNextMajor(from: "0.3.0"))
    ],
    targets: [
        .target(
            name: "RxCoordinator",
            dependencies: [
				"RxResource",
				"RxSwift",
				.product(name: "RxCocoa", package: "RxSwift")
			]
		),
        .testTarget(
            name: "RxCoordinatorTests",
            dependencies: ["RxCoordinator"]),
    ]
)
