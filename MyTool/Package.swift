// Copyright (c) <YEAR> <AUTHOR>

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MyTool",
    platforms: [.macOS(.v26)],

    products: [
        .executable(name: "my-tool", targets: ["MyTool"])
    ],

    dependencies: [
        .package(url: "https://github.com/ouser4629/CmdArgLibCore.git", branch: "main"),
        .package(url: "https://github.com/ouser4629/CmdArgLibMacros.git", branch: "main"), 
        .package(url: "https://github.com/ouser4629/CmdArgLibHelpScreen.git", branch: "main"), 
        .package(url: "https://github.com/ouser4629/CmdArgLibCompletions.git", branch: "main"), 
    ],

    targets: [
        .executableTarget(
            name: "MyTool",
            dependencies: [
                "CmdArgLibCore", "CmdArgLibMacros", "CmdArgLibHelpScreen", "CmdArgLibCompletions", 
            ]
        ),
    ]
)