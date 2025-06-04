// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SelfDB",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        // Main umbrella library
        .library(
            name: "SelfDB",
            targets: ["SelfDB"]),
        
        // Individual module libraries
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
    targets: [
        // Core target with shared utilities
        .target(
            name: "Core",
            dependencies: []),
            
        // Authentication target
        .target(
            name: "Auth",
            dependencies: ["Core"]),
            
        // Database target
        .target(
            name: "Database",
            dependencies: ["Core", "Auth"]),
            
        // Storage target
        .target(
            name: "Storage",
            dependencies: ["Core", "Auth"]),
            
        // Realtime target
        .target(
            name: "Realtime",
            dependencies: ["Core", "Auth"]),
        
        // Main umbrella target
        .target(
            name: "SelfDB",
            dependencies: ["Core", "Auth", "Database", "Storage", "Realtime"]),
            
        // Test targets
        .testTarget(
            name: "SelfDBTests",
            dependencies: ["SelfDB"]),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]),
        .testTarget(
            name: "AuthTests",
            dependencies: ["Auth"]),
        .testTarget(
            name: "DatabaseTests",
            dependencies: ["Database"]),
        .testTarget(
            name: "StorageTests",
            dependencies: ["Storage"]),
        .testTarget(
            name: "RealtimeTests",
            dependencies: ["Realtime"]),
    ]
)
