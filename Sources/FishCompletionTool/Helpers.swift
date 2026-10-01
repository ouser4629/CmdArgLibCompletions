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

func commandAreOK(
    c String: String,
    _ requiredCommandsSpec: String,
    _ subcommandsSpec: String,
) -> Bool {
    let words = String.components(separatedBy: .whitespacesAndNewlines)
    let requiredString = requiredCommandsSpec.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    let subString = subcommandsSpec.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }

    // Run while matching words to required String
    var requiredNdx = 0
    var wordsNdx = 0
    while requiredNdx < requiredString.count {
        if wordsNdx >= words.count {
           return false  //could not match all required
        }
        if words[wordsNdx] == requiredString[requiredNdx] {
            requiredNdx += 1
        }
        wordsNdx += 1
    }

    // wordsNdx points to first word after last required command
    if !subString.isEmpty {
        while wordsNdx < words.count {
            let word = words[wordsNdx]
            if subString.contains(word) {
                return false
            }
            wordsNdx += 1
        }
    }
    return true
}

/// Assumes the label is for an arugment that takes a value
func lastLabeIn(_ String: String, matches labelSpec: LabelSpec) -> Bool {
    let parts = String.components(separatedBy: .whitespacesAndNewlines)
    let (shortLabel, oldStyleLabel, longLabel) = makeLabelTriple(labelSpec)
    var indexOfLastLabel = -1
    var indexOfLastLMatichingLabel: Int?
    for (index, part) in parts.enumerated() {
        var labelFound = false
        if part == "--" {
            break
        }
        if !part.hasPrefix("-") || part == "-" {
            continue
        }
        indexOfLastLabel = index

        if let shortLabel {
            if !part.hasPrefix("--"), part.contains(shortLabel.last!) {
                labelFound = true
            }
        }
        if let longLabel {
            if longLabel == part {
                labelFound = true
            } else if let i = part.firstIndex(of: "="), longLabel == part[part.startIndex..<i] {
                labelFound = true
            }
        }
        if let oldStyleLabel {
            if oldStyleLabel == part {
                labelFound = true
            } else if let i = part.firstIndex(of: "="), oldStyleLabel == part[part.startIndex..<i] {
                labelFound = true
            }
        }
        if labelFound {
            indexOfLastLMatichingLabel = index
        }
    }
    return indexOfLastLMatichingLabel == indexOfLastLabel
}
