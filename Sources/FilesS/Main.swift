//  Copyright (c) 2025-2026 Psummerland2.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import CmdArgLibCommandNodeStruct
import CmdArgLibCompletions
import CmdArgLibHelpScreen

enum Encoding: String, CmdArgEnum { case utf8, utf16, ascii }
typealias File = String
typealias ConfigFile = String
typealias Directory = String
typealias Password = String
typealias Shell = CompletionGenerator

@main
struct Example1: CommandNodeStruct {
    var encoding: Encoding = .utf8
    var password: Password? = nil
    var config: ConfigFile? = nil
    var directory: Directory? = nil
    var files: Variadic<File> = []
    var help: MetaFlag = MetaFlag(helpElements: helpLayout)
    var generateCompletionScript: MetaOption<Shell> = MetaOption(generator)

    func run(state: [Void]) async throws -> [Void]
    {
        print("encoding: \(encoding)")
        print("password: \(password!)")
        print("config: \(config!)")
        print("config: \(encoding)")
        print("directory: \(directory!)")
        print("files: \(files)")
        return []
    }

    var configuration: CommandNodeConfiguration<Void>? = CommandNodeConfiguration<Void>(
        commandName: "ex1",
        embellishments: [
            .embellish("encoding", label: "e__encoding", typeName: "Encoding"),
            .embellish("password", label: "p__password", typeName: "Password"),
            .embellish("config", label: "c__config", typeName: "ConfigFile"),
            .embellish("directory", label: "d__directory", typeName: "Directory"),
            .embellish("files", label: "_", typeName: "Variadic<File>"),
            .embellish("help", label: "h__help"),
            .embellish("generateCompletionScript", typeName: "MetaOption<Shell>")
        ],
    )

    static let helpLayout: [ShowElement] = [
        .text("DESCRIPTION\n", "Do stuff with selected files."),
        .synopsis("\nUSAGE\n", line: ["!generateCompletionScript"]),
        .text("\nOPTIONS"),
        .parameter("help", "Show help information."),
        .parameter("encoding", "Text encoding (\(Encoding.orCases()))", .list(Encoding.cases)),
        .parameter("password", "Password", .exclusive),
        .parameter("config", "Configuration json file", .file("*.json")),
        .parameter("directory", "Backup directory", .directory("*Backup")),
        .parameter("files", "Files", .path),
        .text("\nNOTE\n", note),
    ]

    static let note = """
        There is a hidden meta-option, "$J{generateCompletionScript} $E{generateCompletionScript}",
        where $E{generateCompletionScript} can be \(ShellType.orCases("one of")). If specified,
        a corresponding completion script is printed to standard output.
        """

    static let generator = CompletionGenerator(name: "files-m", suggestionElements: generatorSuggestions)

    static let generatorSuggestions: [ShowElement] = [
        .parameter("help", "", .exclusive),
        .parameter("encoding", "", .list(Encoding.cases)),
        .parameter("password", "", .exclusive),
        .parameter("config", "", .file("*.json")),
        .parameter("directory", "", .directory("*Backup")),
        .parameter("files", "", .path),
        .parameter("generateCompletionScript", "", .ignore),
    ]
}
