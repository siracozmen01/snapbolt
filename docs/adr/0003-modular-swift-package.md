# 0003. Modular local Swift package with compiler-enforced boundaries

- **Status:** Accepted
- **Date:** 2026-10-21

## Context

Utility apps like this tend to grow a few huge files (`AppDelegate.swift`, `CaptureManager.swift`)
that know about everything. That makes open-source contributions hard: every change touches the same
files, and nothing can be tested in isolation. Written rules alone do not prevent it.

## Decision

Put all code in a local Swift package, `Packages/SnapboltKit`, with one module per responsibility
(see [architecture.md](../architecture.md)). Dependency direction is fixed: feature modules depend
only on `SnapboltCore`; `SnapboltWorkflow` depends only on `SnapboltCore`; only the app target
imports concrete feature modules. `Package.swift` encodes these rules so a violation fails the build.

## Alternatives considered

- **Folders inside one app target** — boundaries are a convention only; any file can reach any type.
- **One Xcode framework target per module** — same isolation, but more project configuration and
  slower `swift test` iteration than SwiftPM.

## Consequences

- Each module can be built and tested with `swift test` without launching the app.
- Cross-module API must be `public`, which makes boundaries visible and deliberate.
- Adding a module is a small `Package.swift` change plus an update to `architecture.md`.
- Some indirection: features meet only through Core protocols.
