<!-- 
//  Copyright (c) 2025-2026 Peter Buenafuente Summerland.
//  All rights reserved.
//
//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at https://mozilla.org/MPL/2.0.
-->

## CmdArgLibCompletions

CmdArgLibCompletions is part of the [Command Argument Library](https://github.com/ouser4629/cmd-arg-lib.git). 

It provides [CompletionGenerator](#completiongenerator), a meta-option element for generating shell completion scripts.

---

## Usage


1. Define a completion generator:

```
static let generator = CompletionGenerator(name: "files", suggestionElements: generatorSuggestions)

static let generatorSuggestions: [ShowElement] = [ ... ]
```

2. Define a typealias to improve help screen rendering:

```
typealias Shell = CompletionGenerator
```

3. If you are using the library's macro-based API, add the following parameter to 
the annotated command function:

```
generateCompletionScript: MetaOption<Shell> = MetaOption(generator))
```

4. If you are using the library's struct-based API, add the following variable to the conforming struct:

```
var generateCompletionScript: MetaOption<Shell> = MetaOption(generator)
```

If "--generate-completion-script \<shell>", is encountered in a command argument list, a completion
script for "\<shell>" will be written to standard output.

---

## Examples

This repository includes two examples, `files-m` and `files-s`, that demonstrate the use of the
available [completion rules](#completionrule). They are identical except that the `files-m`  uses
CAL's  macro-based API and `files-s` uses its struct-based API.
<details>
<summary>Help Screen</summary>

```
> files-m -h
DESCRIPTION
  Do stuff with selected files.

USAGE
  files-m [-h] [-e <encoding>] -p <password> -c <config-file> -d <directory>
          <file>...

OPTIONS
  -h/--help                   Show help information.
  -e/--encoding <encoding>    Text encoding ("utf8", "utf16" or "ascii") (default:
                              "utf8").
  -p/--password <password>    Password.
  -c/--config <config-file>   Configuration json file.
  -d/--directory <directory>  Backup directory.
  <file>...                   Files.

NOTE
  There is a hidden meta-option, "--generate-completion-script <shell>", where
  <shell> can be one of "zsh" or "fish". If specified, a corresponding completion
  script is printed to standard output.
```

</details>

<details>
<summary>Code</summary>

```swift

enum Encoding: String, CmdArgEnum { case utf8, utf16, ascii }

typealias File = String
typealias ConfigFile = String
typealias Directory = String
typealias Password = String
typealias Shell = CompletionGenerator

@main
struct Main {

    @MainFunctionMacro
    static func filesM(
        h__help help: MetaFlag = MetaFlag(helpElements: helpLayout),
        e__encoding encoding: Encoding = .utf8,
        p__password password: Password,
        c__config config: ConfigFile,
        d__directory directory: Directory,
        _ files: Variadic<File>,
        generateCompletionScript: MetaOption<Shell> = MetaOption(generator))
    { ... }

    static let helpLayout: [ShowElement] = [ ... ]

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
```

</details>

<details>
<summary>Completions</summary>

```
> tree -L 3
.
├── config1.json
├── config2.jon
├── some.txt
├── Text
│   └── more.txt
└── TextBackup
    └── some.txt~
```

```
> files-m --\<TAB>
--config  --directory  --encoding  --help  --password

> files-m --en\<TAB> -> "> files-m --encoding "

> files-m --encoding \<TAB>
utf8  utf16  ascii

> files-m --encoding 8\<TAB> -> "> files-m --encoding utf8 " 

> files-m --encoding utf8 --password Agent007 -c config
config1.json  config2.json

> files-m --directory \<TAB> -> "> files-m --directory TextBackup "

files-m \<TAB>
config1.json  config2.json  some.txt  Text/  TextBackup/
```

</details>

 ---

## CompletionGenerator

A `CompletionGenerator` specifies the name of the command as it will appear in the completion script, and
an array of show elements. The array contains one `ParameterShowElement` for each parameter to be included
in the completion script. It is not an error for the array to include a `ShowElement` that is 
not a `ParameterShowElement`, but such elements are disregarded. 

Each `ParameterShowElement` is constructed by `.parameter(_:_:_:defaultValueOverride)`.

The constructor's first three parameters specify the subject parameter's name, description, and `CompletionRule`. 
The `defaultValueOverride` parameter, if specified, is ignored. The `CompletionRule` specifies the suggestions
available for the subject parameter.

---

## CompletionRule

A `CompletionRule` describes the suggestions that appear when the CLI user enters, say, `<TAB>`
to request shell completion. CLI labels and flags, like "--name" or "-h", are normally suggested
unless the completion rule is `.ignore`. For all other rules, the suggestion appears after
the associated parameter's CLI label.

* .ignore - don't complete the parameter at all
* .exclusive - complete the parameter's label, but don't provide value suggestions
* .path - suggest using shell path expansion
* .list([String]) - suggest the indicated strings (i.e., enum raw values)
* .file(Glob) - suggest files that match the glob pattern
* .directory(Glob) - suggest directories that match the glob pattern


The default `CompletionRule` is `.exclusive`.

---

## Hierarchical Command CLIs

In CAL, hierarchical commands are represented as a graph of CommandNodes. A valid command hierarchy is a 
strict tree: each node must have exactly one path from the root.

You can generate shell completion for the entire tree by adding a completion generator meta-option parameter to the top-level command node.

When triggered, the completion script generator will recursively traverse the entire tree. It determines
the suggestion elements for a given subcommand by inspecting, in order:

1. the suggestion elements of its completion generator meta-option
2. the parameter show elements of its help meta-flag
3. the parameter show elements of its manual-page meta-flag

If none of these exist, only the command's name, with no associated arguments, is
added to the completion script.

It is often useful, however, to add a completion meta-option to all commands in the hierarchy. In
particular, this allows for abbreviated descriptions (or no description) in suggestion screens.

The [Command Argument Library](https://github.com/ouser4629/cmd-arg-lib.git) repository has an example, 
`Ex04_Advice`, that offers shell completion for a command with subcommands.

---

## Installation

It is recommended that you install the examples using [`caltool`](https://github.com/ouser4629/cmd-arg-lib-tool.git).

<details>
<summary>Installation</summary>

```
> git clone https://github.com/ouser4629/CmdArgLibCompletions.git

> cd CmdArgLibCompletions

> swift build -c release

> caltool install -c fish zsh
files-m
    installed "files-m" in /Users/ps/.local/bin
    installed "files-m.fish" in /Users/ps/.config/fish/completions
    installed "_files-m" in /Users/ps/.config/zsh/completions
files-s
    installed "files-s" in /Users/ps/.local/bin
    installed "files-s.fish" in /Users/ps/.config/fish/completions
    installed "_files-s" in /Users/ps/.config/zsh/completions
    
## Open new tab to refresh completion path

## Make a new directory, say Demo and set up this:

> tree -L 3
.
├── config1.json
├── config2.jon
├── some.txt
├── Text
│   └── more.txt
└── TextBackup
    └── some.txt~

## Experiment with completion

## Go back to the cloned source and clean up

> caltool uninstall
files-m
    uninstalled "files-m" in /Users/ps/.local/bin
    uninstalled "files-m.fish" in /Users/ps/.config/fish/completions
    uninstalled "_files-m" in /Users/ps/.config/zsh/completions
files-s
    uninstalled "files-s" in /Users/ps/.local/bin
    uninstalled "files-s.fish" in /Users/ps/.config/fish/completions
    uninstalled "_files-s" in /Users/ps/.config/zsh/completions
```

</details>

---

## Project Status

This software:

* is licensed under the [Mozilla Public License, v. 2.0 "MPL-2.0"](https://mozilla.org/MPL/2.0)

* is currently in beta (version 0.5.0), and has only been tested for macOS

* requires macOS 12. 

---

## See Also

[CmdArgLibMacros](https://github.com/ouser4629/CmdArgLibMacros.git), 
[CmdArgLibCommandNodeStruct](https://github.com/ouser4629/CmdArgLibCommandNodeStruct.git), 
[CmdArgLibCore](https://github.com/ouser4629/CmdArgLibCore.git) 
