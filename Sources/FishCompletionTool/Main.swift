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

import CmdArgLibCore
import CmdArgLibHelpScreen
import CmdArgLibMacros
import Foundation

@main
struct Main {

    enum ParameterType: String, CmdArgEnum { case basic, variadic, positional }

    /// Determine if a fish completion suggestion is enabled.
    /// - Parameters:
    ///   - parameterType: The case to be checked
    ///   - commandLineOpc: Command line words up to cursor - (commandline -opc)
    ///   - requiredCommands: Required preceding commands, separated by whitespace
    ///   - subcommands: Current command's subcommands, sperated by whitespace.
    ///   - variadicParameterLabelSpec: "The label spec of the variadic parameter"
    ///   - allVariadicParameterLabelSpec: "The label specs of all variadic parameters"
    @MainFunctionMacro()
    static func __cal_fish_completion_tool(
        _ parameterType: ParameterType,
        c commandLineOpc: String,
        _rc_ requiredCommands: String,
        _sc_ subcommands: String,
        _vl_ variadicParameterLabelSpec: String = "",
        _vls_ allVariadicParameterLabelSpec: String = "",
        h__help help: MetaFlag = MetaFlag(helpElements: helpElements))
    {
        var ok = false
        switch parameterType {
        case .basic:
            ok = commandAreOK(c: commandLineOpc, requiredCommands, subcommands)
        case .variadic:
            ok = commandAreOK(c: commandLineOpc, requiredCommands, subcommands) &&
            lastLabeIn(commandLineOpc, matches: variadicParameterLabelSpec)
        case .positional:
            ok = positionalOK(commandLineOpc, requiredCommands, subcommands, allVariadicParameterLabelSpec)
        }
        if ok {
            exit(EXIT_SUCCESS)
        } else {
            exit(EXIT_FAILURE)
        }
    }

    static let helpElements: [ShowElement] = [
        .text("DESCRIPTION\n", "TDetermine if a fish completion suggestion is enabled."),
        .synopsis("\nUSAGE\n"),
        .text("\nPARAMETERS"),
        .parameter("parameterType","The type of parameter involved (\(ParameterType.orCases("one of")))"),
        .parameter("commandLineOpc","Command line words up to cursor - (commandline -opc)"),
        .parameter("requiredCommands","Required preceding commands, separated by whitespace"),
        .parameter("subcommands","Current command's subcommands, sperated by whitespace."),
        .parameter("variadicParameterLabelSpec", "The label spec of the current variadic parameter"),
        .parameter("allVariadicParameterLabelSpec", "The label spec of all variadic parameter"),
        .parameter("help", "Show help information."),
    ]
}

/// Test if can suggest completion for a positional type.
/// - Parameters:
///   - commandLineOpc: Command line words up to cursor - (commandline -opc)
///   - requiredCommands: Required preceding commands, separated by whitespace
///   - subcommands: Current command's subcommands, sperated by whitespace.
///   - allVariadicParameterLabelSpec: "The label specs of all variadic parameters"
func positionalOK(
    _ commandLineOpc: String,
    _ requiredCommands: String,
    _ subcommands: String,
    _ allVariadicParameterLabelSpec: String) -> Bool
{
    if !commandAreOK(c: commandLineOpc, requiredCommands, subcommands) {
        exit(EXIT_FAILURE)
    }
    let variadicLabelSpecs = allVariadicParameterLabelSpec.components(separatedBy: " ").filter { !$0.isEmpty }
    for labelSpec in variadicLabelSpecs {
        if lastLabeIn(commandLineOpc, matches: labelSpec) {
           return false
        }
    }
   return true
}
