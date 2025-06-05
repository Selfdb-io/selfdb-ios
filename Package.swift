// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SelfDB",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .visionOS(.v1)
    ],
    products: [
        // Main product that exports all modules
        .library(
            name: "SelfDB",
            targets: ["SelfDB"]),
        
        // Individual module products for selective imports
        .library(
            name: "SelfDBCore",
            targets: ["Core"]),
        .library(
            name: "SelfDBAuth", 
            targets: ["Auth"]),
        .library(
            name: "SelfDBDatabase",
            targets: ["Database"]),
        .library(
            name: "SelfDBStorage",
            targets: ["Storage"]),
        .library(
            name: "SelfDBRealtime",
            targets: ["Realtime"]),
    ],
    dependencies: [
        // No external dependencies - pure Swift implementation
    ],
    targets: [
        // Core module with shared types and utilities
        .target(
            name: "Core",
            dependencies: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]),
        
        // Auth module
        .target(
            name: "Auth",
            dependencies: ["Core"]),
        
        // Database module
        .target(
            name: "Database",
            dependencies: ["Core", "Auth"]),
        
        // Storage module
        .target(
            name: "Storage",
            dependencies: ["Core", "Auth"]),
        
        // Realtime module
        .target(
            name: "Realtime",
            dependencies: ["Core", "Auth"]),
        
        // Main SelfDB module that imports all others
        .target(
            name: "SelfDB",
            dependencies: ["Core", "Auth", "Database", "Storage", "Realtime"]),
        
        // Test targets
        .testTarget(
            name: "SelfDBTests",
            dependencies: ["SelfDB"]),
    ],
    swiftLanguageVersions: [.v5]
)
