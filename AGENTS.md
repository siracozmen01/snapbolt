# Agent instructions

Instructions for AI coding agents (and a quick reference for humans) working on Snapbolt.
The full rules are in [docs/conventions](docs/conventions/README.md); this file is the summary you
must follow on every change.

## Project

Snapbolt is an open-source (MIT) macOS menu bar app: freeze-frame screenshot → select region or
window → upload to S3-compatible storage (Cloudflare R2 first) → link on the clipboard.
Swift 6, macOS 15+, AppKit + SwiftUI, ScreenCaptureKit.

- Architecture: [docs/architecture.md](docs/architecture.md)
- Decisions: [docs/adr](docs/adr/README.md)
- Current spec: [docs/specs/2026-10-21-snapbolt-phase-1-design.md](docs/specs/2026-10-21-snapbolt-phase-1-design.md)

## Commands

```bash
make bootstrap   # install XcodeGen and SwiftLint (Homebrew)
make project     # generate Snapbolt.xcodeproj from project.yml
make build       # build the app
make test        # run all package tests (make test FILTER=<TestTarget>)
make lint        # SwiftLint --strict + swift format lint --strict
make format      # apply swift-format
```

Run `make lint` and `make test` before declaring any change done.

## Hard rules

1. **Module boundaries.** Code lives in `Packages/SnapboltKit/Sources/<Module>`. Feature modules
   import only `SnapboltCore`. `SnapboltWorkflow` imports only `SnapboltCore`. Only `App/` imports
   concrete feature modules. Never add a dependency between feature modules.
2. **No god files.** One primary type per file. Files ≤ 300 lines, types ≤ 200, functions ≤ 40
   (SwiftLint errors). Split by responsibility; never disable these rules.
3. **Banned names:** `Manager`, `Helper`, `Utils`, `Common`, `Misc`, `Service` (alone), `Handler`
   (alone), `Base…`. Name the responsibility.
4. **No `!`, `try!`, `as!`** in production code. **No `try?` or empty `catch`** without a
   justification comment. **No `print`** — use the module's `logger`.
5. **No singletons or global mutable state.** Inject dependencies through initializers.
6. **Swift 6 strict concurrency.** UI is `@MainActor`; Core types are `Sendable` values; no GCD.
7. **Never log secrets.** URLs, keys and paths are logged with `privacy: .private`.
8. **No new third-party dependencies** without an ADR ([ADR 0006](docs/adr/0006-dependency-policy-and-keyboardshortcuts.md)).
9. **English everywhere.** Code, comments, docs, commits.
10. **Tests with behaviour changes.** Swift Testing; fakes are hand-written; no real network.

## Style in one screen

- `swift format` owns formatting: 4 spaces, 120 columns, trailing commas.
- `///` DocC comments on every `public` declaration; inline `//` comments explain **why**, never what.
- `TODO(#issue)` only — bare TODOs fail lint. No commented-out code. No file header comments.
- Protocols are capabilities (`Uploading`), implementations say how (`S3Uploader`).
- Coordinate spaces are named in identifiers (`rectInPixels`); conversions only in
  `SnapboltCore/Geometry`.

## Workflow

- Branch `<type>/<description>`; Conventional Commits (`feat(upload): …`); small PRs, squash-merged.
- Update `CHANGELOG.md` (Unreleased) for user-visible changes and `docs/architecture.md` for
  structural ones.
- UI or capture changes: run the relevant parts of [docs/testing.md](docs/testing.md) and say so in
  the PR.
