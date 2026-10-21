# Conventions

These rules apply to every file in the repository, whoever or whatever writes it. Where a tool can
check a rule, the tool is the authority and CI enforces it; the documents explain the intent.

| Document | Covers |
|---|---|
| [code-style.md](code-style.md) | Formatting, language features, access control, AppKit vs SwiftUI |
| [naming.md](naming.md) | Types, protocols, functions, files, banned names |
| [file-organization.md](file-organization.md) | Size limits, one type per file, folder layout inside a module |
| [comments.md](comments.md) | Doc comments, inline comments, `MARK`, `TODO` |
| [error-handling.md](error-handling.md) | Error types, `try?`, user-facing errors, logging |
| [concurrency.md](concurrency.md) | Actors, `Sendable`, tasks, main-actor rules |
| [testing.md](testing.md) | What to test, how to name and structure tests, fakes |
| [git-workflow.md](git-workflow.md) | Branches, commits, pull requests, releases |

## Language

Everything in the repository is written in **English**: code, comments, documentation, commit
messages, issues and pull requests. User-facing strings are English in Phase 1 and go through
`String(localized:)` so they can be translated later.

## Changing a rule

Open a pull request that changes the document and, if relevant, the tool configuration
(`.swiftlint.yml`, `.swift-format`) together. Rules that affect architecture need an
[ADR](../adr/README.md).
