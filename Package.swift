// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "WildwellCore", platforms: [.macOS(.v14)], products: [.library(name: "WildwellCore", targets: ["WildwellCore"])], targets: [
    .target(name: "WildwellCore", path: "Wildwell", exclude: ["WildwellApp.swift", "Artwork.swift", "PracticeViews.swift", "JournalViews.swift", "Assets.xcassets"], sources: ["Models.swift", "Store.swift"]),
    .testTarget(name: "WildwellCoreTests", dependencies: ["WildwellCore"], path: "Tests")
])
