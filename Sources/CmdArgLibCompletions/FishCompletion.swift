//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

import CmdArgLibCore
import Foundation

struct FishCompletion {
    static public func generate(
        maybeName: String?,
        context: RunContext,
        suggestionElements: [ShowElement] = []) -> String
    {
        let name = maybeName ?? context.name
        let subnodes = suggestionElements.commandContexts
        let maker = makeRunContextMaker(thatMakes: context)
        let newNode = CommandContext(name: name, synopsis: "PHONEY", runContextMaker: maker, subnodes: subnodes)
        let functionDefinitions = [fishEnableCompletionScript(for: newNode.name)]
        let lines = commandContextLines(for: newNode, callNames: [], scriptLines: functionDefinitions)
        let script = lines.joined(separator: "\n")
        return script
    }
}

extension FishCompletion {

    fileprivate static func fishEnableCompletionScript(for name: String) -> String
    {
        let script = """
            #!/usr/bin/env fish

            ### Fish commpletion script for '\(name)'
            #
            #   1. The script assumes that the __cal_fish_completion_tool has been installed.
            #   2. The script itself, named '\(name).fish', must be installed.
            #      A typical location for fish completion scripts is '~/.config/fish/completions/'
            #   3. Your progam must be run as '> <\(name)> ...', not '> ./<\(name)> ...'
            #

            function __cal_fish_basic -a requiredCommands subcommands
              __cal_fish_completion_tool basic -c "$(commandline -opc)" -rc "$requiredCommands" -sc "$subcommands"
            end

            function __cal_fish_variadic -a requiredCommands subcommands labelSpec
              __cal_fish_completion_tool variadic -c "$(commandline -opc)" -rc "$requiredCommands" -sc "$subcommands" -vl "$labelSpec"
            end

            function __cal_fish_positional -a requiredCommands subcommands labelsSpec
              __cal_fish_completion_tool positional -c "$(commandline -opc)" -rc "$requiredCommands" -sc "$subcommands" -vls "$labelsSpec"
            end

            """
        return script
    }
}

extension FishCompletion {

    static func commandContextLines(
        for commandContext: CommandContext,
        callNames: [String],
        scriptLines: [String]) -> [String]
    {
        var newScriptLines = scriptLines
        let subNodeNames = commandContext.children.map(\.name)
        let newCallNames = callNames + [commandContext.name]
        let names = newCallNames.joined(separator: " ")
        let programName = newCallNames.first!
        var runContext = commandContext.runContextMaker()
        let completionElements: [ShowElement] = runContext.primaryShowElementsForCompletions
        let ruleForNameDict = ShowElement.ruleForNameDictionary(for: completionElements)
        var descriptionForNameDict = ShowElement.descriptionForNameDictionary(for: completionElements)
        for (key, value) in descriptionForNameDict {
            let newValue = runContext.expandShowMacros(in: value)
            descriptionForNameDict.updateValue(newValue, forKey: key)
        }
        newScriptLines.append("complete -c \(programName) -n '__cal_fish_basic \"\(names)\"' -f")
        if let line = makeSubcommandsLine(callNames: newCallNames, subcommandNames: subNodeNames) {
            newScriptLines.append(line)
        }
        runContext.resetParameterNamedDictionary()
        let showElements = runContext.primaryShowElementsForCompletions
        var parametersWithCompletion: [Parameter] = runContext.parameters
        if !showElements.isEmpty {
            var showSet: Set<String> = []
            for parameterShowElement in showElements.parameterShowElements {
                showSet.insert(parameterShowElement.name)
            }
            parametersWithCompletion = runContext.parameters.filter { showSet.contains($0.name) }
        }
        let lines = fishCompletionLinesFor(
            parametersWithCompletion,
            ruleFor: ruleForNameDict,
            descriptionFor: descriptionForNameDict,
            callNames: newCallNames,
            subcommandNames: subNodeNames)
        newScriptLines.append(contentsOf: lines)
        let subnodes = showElements.commandContexts
        for subNode in subnodes {
            newScriptLines = commandContextLines(for: subNode, callNames: newCallNames, scriptLines: newScriptLines)
        }
        return newScriptLines
    }

    fileprivate static func makeSubcommandsLine(
        callNames: [String],
        subcommandNames: [String]) -> String?
    {
        if subcommandNames.isEmpty { return nil }
        guard let name = callNames.first else { return nil }
        let cns = callNames.joined(separator: " ")
        let scns = subcommandNames.joined(separator: " ")
        let line = #"complete -c \#(name) -n '__cal_fish_basic "\#(cns)" "\#(scns)"'  -r -f -k -a '\#(scns)'"#
        return line
    }
}

extension FishCompletion {

    /// Generate commpletion lines for an array of parameters
    /// - Parameters:
    ///   - parameters: Array of paramteters for which completions are to be generated
    ///   - ruleFor: A dictionary mapping parameter names to completioon rule.
    ///   - descriptionFor: A dictionary mapping parameter names to descriptions.
    ///   - callNames: Command call names
    ///   - subcommandNames: Subcommand names
    /// - Returns: Returns a list of Fish completion lines
    ///
    /// The subcommands names are necessary to disable the lines after a subcommand (which then
    /// has its own fish completion lines.
    fileprivate static func fishCompletionLinesFor(
        _ unorderedParameters: [Parameter],
        ruleFor: [String: CompletionRule],
        descriptionFor: [String: String],
        callNames: [String],
        subcommandNames: [String] = [] ) -> [String]
    {
        var postionalParmaters: [Parameter] = []
        var otherParameters: [Parameter] = []
        for p in unorderedParameters {
            if p.isPositional {
                postionalParmaters.append(p)
            } else {
                otherParameters.append(p)
            }
        }
        let parameters = otherParameters + postionalParmaters
        let sumbcommandNamesString: String = subcommandNames.joined(separator: " ")
        var variadicLabelSpecs: [String] = []
        for parameter in parameters {
            if parameter.isVariadic {
                let labelSpec = parameter.labelSpec
                if labelSpec != "_" { variadicLabelSpecs.append(labelSpec) }
            }
        }
        let variadicLabelSpecsString = variadicLabelSpecs.joined(separator: " ")
        var lines: [String] = []
        for parameter in parameters {
            let rule = ruleFor[parameter.name] ?? .exclusive
            switch rule {
            case .ignore: continue
            default: break
            }
            let parameterLines = fishCompletionLinesFor(
                parameter: parameter,
                callChain: callNames,
                completionRule: rule,
                description: descriptionFor[parameter.name],
                subcommandNames: sumbcommandNamesString,
                variadicLabelSpecs: variadicLabelSpecsString
            )
            lines += parameterLines
        }
        return lines
    }

    /// Completion line, if any for a parameter
    /// - Parameters:
    ///   - parameter: The parameter for which completion lines are being generated.
    ///   - callChain: The command coall chain.
    ///   - completionRule: The completion rule for this parameter
    ///   - subcommandNames: Names of subcommands
    ///   - variadicLabelSpecs: label specs of all variadic (not postional) parameters.
    /// - Returns: A completin line or nil
    ///
    /// The names of subcommands are required so the the parameter;s lines are disabled after a subcommand
    /// The variadic label specs are required so that that only one variadic is in control at a time.
    fileprivate static func fishCompletionLinesFor(
        parameter: Parameter,
        callChain: [String],
        completionRule: CompletionRule,
        description: String?,
        subcommandNames: String = "",
        variadicLabelSpecs: String = "" ) -> [String]
    {
        let name = callChain.first ?? "error"
        let commandChain = callChain.joined(separator: " ")
        var descriptionTag = ""
        if parameter.isArray {
            descriptionTag = " -d 'A \(parameter.typeElementName)'"
        }
        if var description {
            if let firstLeft = description.firstIndex(of: "(") {
                description = String(description[..<firstLeft].trimmingCharacters(in: .whitespacesAndNewlines))
            }
            description = description.replacingOccurrences(of: "'", with: "\\'")
            descriptionTag = " -d '\(description)'"
        }

        var shortLabel = ""
        var oldStyleLabel = ""
        var longLabel = ""
        if let short = parameter.shortLabelName {
            shortLabel += " -s \(short)"
        }
        if let oldStyle = parameter.oldStyleLabelName {
            oldStyleLabel = " -o \(oldStyle)"
        }
        if let long = parameter.longLabelName {
            longLabel = " -l \(long)"
        }
        let labels = shortLabel + oldStyleLabel + longLabel

        let condition: String
        if parameter.isPositional {
            condition =
                "complete -c \(name) -n '__cal_fish_positional \"\(commandChain)\" \"\(subcommandNames)\" \"\(variadicLabelSpecs)\"'"
        } else {
            condition = "complete -c \(name) -n '__cal_fish_basic \"\(commandChain)\" \"\(subcommandNames)\"'"
        }

        if parameter.isFlagOrMetaFlag {
            return [condition + labels + descriptionTag]
        }

        let suggestion = suggestionFor(completionRule, labels: labels, descriptionTag: descriptionTag)
        if suggestion.isEmpty {
            return []
        }

        var lines = ["\(condition)\(labels) \(suggestion)"]
        if parameter.isVariadic && !parameter.isPositional {
            let spec = parameter.labelSpec
            let line =
                "complete -c \(name) -n '__cal_fish_variadic \"\(commandChain)\" \"\(subcommandNames)\" \"\(spec)\"' \(suggestion)"
            lines.append(line)
        }
        return lines
    }

    fileprivate static func suggestionFor(
        _ completionRule: CompletionRule,
        labels: String,
        descriptionTag: String) -> String
    {
        var suggestion = ""
        switch completionRule {
        case .ignore:
            suggestion = ""
        case .exclusive:
            suggestion = "-r -f"
        case .path:
            suggestion = labels.isEmpty ? "-F" : "-r -F"
        case .list(let choices):
            suggestion = "-r -f -k -a '\(choices.map{"\($0)\\t"}.joined(separator: " "))'"
        case .file(var glob):
            glob = glob.isEmpty ? "*" : glob
            suggestion = "-r -f -a '(for f in \(glob);if test -f \"$f\";echo $f;end;end)'"
        case .directory(var glob):
            glob = glob.isEmpty ? "*" : glob
            suggestion = "-r -f -a '(for f in \(glob);if test -d \"$f\";echo $f;end;end)'"
        @unknown default:
            break
        }
        return suggestion + descriptionTag
    }
}
