# 0005. macOS 15 as the minimum deployment target

- **Status:** Accepted
- **Date:** 2026-10-21

## Context

ScreenCaptureKit gained important APIs in recent releases:

- macOS 14: `SCScreenshotManager` for still images.
- macOS 15: `SCRecordingOutput`, which writes a stream straight to a movie file (needed in Phase 3);
  `captureImage(in:)` for a screen rect arrived in 15.2.

Supporting macOS 14 would mean writing our own `AVAssetWriter` pipeline for recording. macOS 26 adds
nothing Snapbolt needs.

## Decision

The minimum deployment target is **macOS 15.0**. APIs newer than 15.0 are used only behind
`if #available` with a working fallback.

## Alternatives considered

- **macOS 14** — larger audience, but a hand-written recording pipeline in Phase 3.
- **macOS 26** — no needed APIs; excludes many users.

## Consequences

- Phase 3 recording uses `SCRecordingOutput` directly.
- Users on macOS 14 or older cannot run Snapbolt.
- CI runs on `macos-15` runners.
