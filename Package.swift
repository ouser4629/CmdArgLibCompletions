//  Copyright (c) 2025-2026 Psummerland2.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CmdArgLibCompletions",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CmdArgLibCompletions", targets: ["CmdArgLibCompletions"]),
        .executable(name: "files-m", targets: ["FilesM"]),
        .executable(name: "files-s", targets: ["FilesS"])
    ],
    dependencies: [
        .package(url: "https://github.com/ouser4629/CmdArgLibCore.git", branch: "main"),
        .package(url: "https://github.com/ouser4629/CmdArgLibMacros.git", branch: "main"),
        .package(url: "https://github.com/ouser4629/CmdArgLibCommandNodeStruct.git", branch: "main"),
        .package(url: "https://github.com/ouser4629/CmdArgLibHelpScreen.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "CmdArgLibCompletions",
            dependencies: [ "CmdArgLibCore" ]
        ),
        .executableTarget(
            name: "FilesM",
            dependencies: ["CmdArgLibCore", "CmdArgLibHelpScreen", "CmdArgLibMacros", "CmdArgLibCompletions"]
        ),
        .executableTarget(
            name: "FilesS",
            dependencies: ["CmdArgLibCore", "CmdArgLibHelpScreen", "CmdArgLibCommandNodeStruct", "CmdArgLibCompletions"]
        ),
    ]
)
