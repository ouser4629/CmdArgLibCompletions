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
import Foundation

@main
struct Main {

    static func main() {
        let args = CommandLine.arguments
        let argsCount = args.count
        if argsCount < 3 {
            exit(EXIT_FAILURE)
        }
        let parameterType = args[1]
        let commandLineOpc = args[2]
        let requiredCommands = argsCount > 3 ? args[3] : ""
        let subcommands = argsCount > 4 ? args[4] : ""
        let variadicParameterLabelSpec = argsCount > 5 ? args[5] : ""
        let allVariadicParameterLabelSpec = variadicParameterLabelSpec
        var ok = false
        switch parameterType {
        case "basic":
            ok = commandAreOK(c: commandLineOpc, requiredCommands, subcommands)
        case "variadic":
            ok = commandAreOK(c: commandLineOpc, requiredCommands, subcommands) &&
            lastLabeIn(commandLineOpc, matches: variadicParameterLabelSpec)
        case "positional":
            ok = positionalOK(commandLineOpc, requiredCommands, subcommands, allVariadicParameterLabelSpec)
        default:
            ok = false
        }
        if ok {
            exit(EXIT_SUCCESS)
        } else {
            exit(EXIT_FAILURE)
        }
    }

    /// Test if can suggest completion for a positional type.
    /// - Parameters:
    ///   - commandLineOpc: Command line words up to cursor - (commandline -opc)
    ///   - requiredCommands: Required preceding commands, separated by whitespace
    ///   - subcommands: Current command's subcommands, sperated by whitespace.
    ///   - allVariadicParameterLabelSpec: "The label specs of all variadic parameters"
    static func positionalOK(
        _ commandLineOpc: String,
        _ requiredCommands: String,
        _ subcommands: String,
        _ allVariadicParameterLabelSpec: String) -> Bool
    {
        if !commandAreOK(c: commandLineOpc, requiredCommands, subcommands) {
            return false
        }
        let variadicLabelSpecs = allVariadicParameterLabelSpec.components(separatedBy: " ").filter { !$0.isEmpty }
        for labelSpec in variadicLabelSpecs {
            if lastLabeIn(commandLineOpc, matches: labelSpec) {
                return false
            }
        }
        return true
    }
}
