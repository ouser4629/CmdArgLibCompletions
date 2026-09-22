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
import Foundation

public typealias ShellType = CompletionGenerator.ShellId

public struct CompletionGenerator: MetaOptionElement, Sendable
{
    public let showElements: [ShowElement]

    public let metaTypeFunction: CmdArgLibCore.MetaTypeFunction?

    public enum ShellId: String, CmdArgEnum { case zsh, fish }

    public init(name maybeName: String? = nil, suggestionElements: [ShowElement] = [])
    {
        @Sendable
        func function(callNames: [String], values: [String], context: RunContext) -> Exception {
            if values.isEmpty {
                return Exception.error("No shell specified for completion script")
            }
            if values.count > 1 {
                return Exception.error("Only one shell can be specified")
            }
            guard let shellType = ShellId(rawValue: values[0]) else {
                return Exception.error("Unrecognized shell: \(values.first ?? "none")")
            }
            var script: String = ""
            switch shellType {
            case .fish:
                script = FishCompletion.generate(maybeName: maybeName, context: context, suggestionElements: suggestionElements)
            case .zsh:
                script = ZshCompletion.generate(maybeName: maybeName, context: context, suggestionElements: suggestionElements)
            }
            return Exception.stdout(script)
        }
        metaTypeFunction = function
        self.showElements = suggestionElements
    }
}

extension RunContext {
    var primaryShowElementsForCompletions: [ShowElement] {
        let metaTypes = self.metaTypes
        var metaType = metaTypes.first(where: { $0.isCompletionMetaType })
        metaType = metaType ?? metaTypes.first(where: { $0.isHelpMetaType })
        metaType = metaType ?? metaTypes.first(where: { $0.isManpageMetaType })
        return metaType?.showElements ?? []
    }
}
