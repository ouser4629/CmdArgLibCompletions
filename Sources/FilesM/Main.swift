// Copyright (c) 2025-2026 Peter Summerland LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// swift-tools-version: 6.2

import CmdArgLibCore
import CmdArgLibMacros
import CmdArgLibCompletions
import CmdArgLibHelpScreen
import Foundation

enum Encoding: String, CmdArgEnum { case utf8, utf16, ascii }
typealias File = String
typealias ConfigFile = String
typealias Directory = String
typealias Password = String
typealias Shell = CompletionGenerator

@main
struct Main {

    @MainFunctionMacro
    static func completionFilesM(
        h__help help: MetaFlag = MetaFlag(helpElements: helpLayout),
        e__encoding encoding: Encoding = .utf8,
        p__password password: Password,
        c__config config: ConfigFile,
        d__directory directory: Directory,
        _ files: Variadic<File>,
        generateCompletionScript: MetaOption<Shell> = MetaOption(generator))
    {
        print("encoding: \(encoding)")
        print("password: \(password)")
        print("config: \(config)")
        print("config: \(encoding)")
        print("directory: \(directory)")
        print("files: \(files)")
    }

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

    static let generator = CompletionGenerator(name: "completion-files-m", suggestionElements: generatorSuggestions)

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
