//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import Foundation

struct ZshCompletion {

    static public func generate(
        maybeName: String?,
        context: RunContext,
        suggestionElements: [ShowElement] = []) -> String
    {
        let name = maybeName ?? context.name
        let subnodes = suggestionElements.commandContexts
        let maker = makeRunContextMaker(thatMakes: context)
        let newContext = CommandContext(name: name, synopsis: "PHONEY", runContextMaker: maker, subnodes: subnodes)
        let setupLines: [String] = ["#compdef \(newContext.name)", ""]
        var lines = commandContextFunctions(for: newContext, callNames: [], scriptLines: setupLines)
        lines.append("_\(newContext.name)")
        let script = lines.joined(separator: "\n")
        return script
    }
}

extension ZshCompletion {

    private static func commandContextFunctions(
        for commandContext: CommandContext,
        callNames: [String],
        scriptLines: [String]) -> [String]
    {
        let newCallNames = callNames + [commandContext.name]
        var newScriptLines = scriptLines + functionLines(callNames: newCallNames, commandContext: commandContext)
        for subcmd in commandContext.children {
            newScriptLines = commandContextFunctions(
                for: subcmd, callNames: newCallNames, scriptLines: newScriptLines)
        }
        return newScriptLines
    }

    private static func functionLines(
        callNames: [String],
        commandContext: CommandContext) -> [String]
    {
        var runContext = commandContext.runContextMaker()
        runContext.resetParameterNamedDictionary()
        let showElements: [ShowElement] = runContext.primaryShowElementsForCompletions
        var parametersSubjectToCompletion: [Parameter] = []
        if !showElements.isEmpty {
            var showSet: Set<String> = []
            for showElement in showElements {
                if let name = showElement.parameterElementName { showSet.insert(name) }
            }
            parametersSubjectToCompletion = runContext.parameters.filter { showSet.contains($0.name) }
        }
        let functionName = funcNameFor(callNames)
        var lines: [String] = []
        lines.append("\(functionName)() {")
        if parametersSubjectToCompletion.isEmpty && commandContext.children.isEmpty {
            lines.append("  return 1")
            lines.append("}")
            return lines
        }
        lines.append(contentsOf: ["  local -i ret=1", "  local -ar arg_specs=("])

        let ruleFor = ShowElement.ruleForNameDictionary(for: showElements)
        let descriptionFor = ShowElement.descriptionForNameDictionary(for: showElements)
        for parameter in parametersSubjectToCompletion {
            let rule = ruleFor[parameter.name] ?? .exclusive
            var description = ""
            if let d = descriptionFor[parameter.name] {
                var expanded = runContext.expandShowMacros(in: d)
                if let firstLeft = expanded.firstIndex(of: "(") {
                    expanded = String(expanded[..<firstLeft].trimmingCharacters(in: .whitespacesAndNewlines))
                }
                expanded = expanded.replacingOccurrences(of: "'", with: "'\\''")
                description = "[\(expanded)]"
            }
            switch rule {
            case .ignore:
                continue
            default:
                lines.append(parameterLineFor(parameter, rule: rule, description: description))
            }
        }
        lines.append("    '(-): :->command'")
        lines.append("    '(-)*:: :->arg'")
        lines.append("  )")
        lines.append("  _arguments -w -s -S : \"${arg_specs[@]}\" && ret=0")
        if !commandContext.children.isEmpty {
            lines.append(contentsOf: caseLinesFor(callNames, and: commandContext.children))
        }
        lines.append("  return \"${ret}\"")
        lines.append("}")
        lines.append("")
        return lines
    }

    // Note that variadics don't work. Only the first element will be suggested.
    // Fixing this requires deep knowledge of zsh's completion module
    fileprivate static func parameterLineFor(
        _ parameter: Parameter,
        rule: CompletionRule,
        description: String ) -> String
    {
        let typeName = "\(SymbolFormatter.snake(parameter.typeElementName))"
        var line = ""
        // labels is [short, oldStyle, long]
        let labels = parameter.definedLabels
        if labels.isEmpty {
            let star = parameter.isRepeatable ? "*" : ""
            var code = "\(star):\(typeName):"
            if let action = actionFor(rule) {
                code = code + action
            }
            return "    '\(code)'"
        }
        // This is so that values can follow immediately after a short label and after a long label with =
        var suffixedLabels = labels
        if !parameter.isFlagOrMetaFlag {
            let labels = parameter.allLabels
            let newShortFlag = labels[0].isEmpty ? "" : "\(labels[0])+"
            let newOldStyleFlag = labels[1].isEmpty ? "" : "\(labels[1])="
            let newLongFlag = labels[2].isEmpty ? "" : "\(labels[2])="
            suffixedLabels = [newShortFlag, newOldStyleFlag, newLongFlag].filter { !$0.isEmpty }
        }

        let prefix = parameter.isRepeatable ? "'*'" : "'(\(labels.joined(separator: " ")))'"
        var labelSpec = "\(suffixedLabels.joined(separator: ","))"
        if suffixedLabels.count > 1 {
            labelSpec = "{\(labelSpec)}"
        }
        if parameter.isFlagOrMetaFlag {
            line = "\(prefix)\(labelSpec)'\(description)'"
        } else if let action = actionFor(rule) {
            line = "\(prefix)\(labelSpec)'\(description):\(typeName):\(action)'"
        }
        return "    \(line)"
    }

    fileprivate static func actionFor(_ completionRule: CompletionRule) -> String?
    {
        var action: String? = nil
        switch completionRule {
        case .ignore:
            break
        case .exclusive:
            return " "
        case .path:
            action = "_files"
        case .list(let members):
            action = "(\(members.joined(separator: " ")))"
        case .file(let glob):
            action = glob.isEmpty ? "_files" : "_files -g '\\''\(glob)'\\''"
        case .directory(let glob):
            action = glob.isEmpty ? "_files -/" : "_files -/ -g '\\''(glob)'\\''"
        }
        return action
    }

    private static func caseLinesFor(
        _ callNames: [String],
        and subnodes: [CommandContext]) -> [String]
    {
        var lines: [String] = []
        lines.append(contentsOf: [
            "  case $state in", "    (command)", "      local subcommands", "      subcommands=(",
        ])
        for node in subnodes {
            lines.append("        '\(node.name):\(node.synopsis)'")
        }
        lines.append("      )")
        lines.append("      _describe \"subcommand\" subcommands")
        lines.append(contentsOf: ["      ;;", "    (arg)", "      case ${words[1]} in"])
        let names = subnodes.map { $0.name }
        let funcName = funcNameFor(callNames)
        for name in names {
            lines.append("        (\(name))")
            lines.append("          \(funcName)_\(name)")
            lines.append("          ;;")
        }
        lines.append("      esac")
        lines.append("      ;;")
        lines.append("  esac")
        return lines
    }

    private static func funcNameFor(_ callNames: [String]) -> String
    {
        guard var first = callNames.first else { return "" }
        first = "_\(first)"
        var rest = callNames.dropFirst(1).map { $0.replacingOccurrences(of: "-", with: "_") }
        rest = [first] + rest
        return rest.joined(separator: "_")
    }
}
