// Copyright (c) <YEAR> <AUTHOR>

import CmdArgLibCore
import CmdArgLibMacros
import CmdArgLibHelpScreen 
import CmdArgLibCompletions

@main
struct Main {
    typealias Shell = CompletionGenerator
    static let generator = CompletionGenerator(name: "my-tool", suggestionElements: helpElements)
    typealias Count = Int
    enum Animal: String, CmdArgEnum { case bear, fox, wolf }

    @MainFunctionMacro
    static func myTool(
        generateCompletionScript : MetaOption<Shell> = MetaOption(generator),
        i__index index: Flag = false,
        c__count count: Count = 1,
        _ animals: [Animal], 
        v__version version: MetaFlag = MetaFlag(string: "version 0.1.0"),
        h__help help: MetaFlag = MetaFlag(helpElements: helpElements),
    ) throws {
        let text = try showAnimals(animals, count: count, index: index)
        throw Exception.stdout(text)
    }

    static let helpElements: [ShowElement] = [
        .text("DESCRIPTION\n", "Print lines containing the names of animals."),
        .synopsis("\nUSAGE\n"),
        .text("\nARGUMENT"),
        .parameter("animals", "The name of an animal (can be repeated)", .list(Animal.cases)),
        .text("\nOPTIONS"),
        .parameter("count", "The number of times to repeat the line"),
        .parameter("index", "Prefix each line with an index"),
        .parameter("help", "Show this help message"),
        .parameter("version", "Show version information"), 
        .parameter("generateCompletionScript", "Generate a completion script for \(ShellType.orCases())"),
        .text("\nNOTES\n", note1),
        .text("\n", note2),
    ]

    static let note1 = """
        The available animals are \(Animal.casesJoinedWith("and")).
        """

    static let note2 = """
        The value $T{count}, if specified, must be between 1 and 3.
        """
}

extension Main {
    static func showAnimals(_ animals: [Animal], count: Count, index: Bool) throws -> String {
        if count < 1 || count > 3 {
            throw Exception.error("$T{count} must be between 1 and 3.")
        }
        let animalsString = string(of: animals)
        var lines: [String] = []
        for i in 1...count {
            let indexString = index ? "\(i): " : ""
            lines.append(indexString + animalsString)
        }
        return lines.joined(separator: "\n")
    }

    static func string(of animals: [Animal]) -> String {
        animals.map { $0.rawValue }.joinedWith("and")
    }
}