//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.

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
