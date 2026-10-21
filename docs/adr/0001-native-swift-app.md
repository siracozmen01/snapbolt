# 0001. Native Swift app

- **Status:** Accepted
- **Date:** 2026-10-21

## Context

Snapbolt captures the screen, draws a full-screen selection overlay, registers global shortcuts,
records video (Phase 3) and lives in the menu bar. All of these are macOS system APIs
(ScreenCaptureKit, AppKit, Carbon events, AVFoundation). The app runs all day in the background, so
memory and startup cost matter.

## Decision

Write Snapbolt as a native macOS app in Swift 6. Use AppKit where precise window control is needed
(overlay panels, menu bar) and SwiftUI for forms (settings, onboarding).

## Alternatives considered

- **Electron / Tauri** — would still need native code for ScreenCaptureKit and the overlay, adds a
  web runtime to a background utility, and splits the codebase across languages.
- **SwiftUI only** — cannot yet express borderless, screen-saver-level panels per display with the
  control the overlay needs.

## Consequences

- Small binary, low idle memory, direct access to every capture API.
- macOS only. Contributors need a Mac with Xcode.
- AppKit and SwiftUI coexist; [conventions/code-style.md](../conventions/code-style.md) says which
  to use where.
