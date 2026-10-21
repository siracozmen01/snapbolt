# 0006. Third-party dependency policy; adopt KeyboardShortcuts

- **Status:** Accepted
- **Date:** 2026-10-21

## Context

Every dependency is code we ship, must keep updated and must trust with screen contents and storage
credentials. At the same time, some problems are solved well by small, focused packages.

Global shortcuts need two things: registering hotkeys system-wide and a control that lets users
record a new shortcut. The recorder is a surprising amount of work (key symbol rendering, conflicts
with system shortcuts, persistence). [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts)
(MIT) does both, uses Carbon hotkeys (no Accessibility permission) and is widely used.

## Decision

### Policy

A third-party package may be added only if all of these hold:

1. It solves a problem that would take significant effort to solve well ourselves.
2. Its license is compatible with MIT (MIT, BSD, Apache-2.0, ISC, zlib).
3. It is actively maintained and supports Swift 6 strict concurrency.
4. It is imported by **exactly one** Snapbolt module that wraps it behind our own API, so it can be
   replaced without touching other modules.
5. It is pinned to a minor version range (`.upToNextMinor`) and the addition is recorded in an ADR.

Packages that touch credentials, networking or image data (e.g. AWS SDKs, analytics, crash
reporters that upload data) are not accepted.

### KeyboardShortcuts

Adopt KeyboardShortcuts, imported only by `SnapboltHotkeys`.

## Alternatives considered

- **Carbon `RegisterEventHotKey` + a hand-written recorder** — feasible, but the recorder is a large
  surface for bugs with no product benefit.
- **`NSEvent.addGlobalMonitorForEvents`** — requires the Accessibility permission and cannot
  consume the key press.

## Consequences

- Shortcut recording works with very little code.
- If the package becomes unmaintained, only `SnapboltHotkeys` changes.
