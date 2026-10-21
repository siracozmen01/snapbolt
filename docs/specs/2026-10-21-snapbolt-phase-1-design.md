# Snapbolt — Phase 1 Design: Capture & Upload

- **Status:** Draft, awaiting review
- **Date:** 2026-10-21
- **Owner:** @siracozmen01

## 1. Summary

Snapbolt is an open-source (MIT) macOS menu bar app that captures the screen and uploads the result
to any S3-compatible storage, with Cloudflare R2 as the primary target. It fills the gap left by
ShareX, which does not exist on macOS.

Phase 1 delivers the core loop: **press a shortcut → select a region or window on a frozen screen →
the image is saved locally, uploaded, and its public link is on the clipboard.**

## 2. Problem

1. There is no ShareX-style "capture → upload → link" tool on macOS that is free, open source and
   works with the user's own bucket.
2. The built-in macOS region capture (⌘⇧4 / ⌘⇧5) uses the live cursor. Games that lock the cursor
   to the window centre (e.g. Minecraft) make region selection impossible: the crosshair stays stuck
   in the middle of the screen.

## 3. Goals and non-goals

### Goals (Phase 1)

- Global shortcuts for region/window capture and full-screen capture.
- Freeze-frame capture: the screen is captured *before* any UI appears; selection happens on the
  frozen image. This fixes the cursor-lock problem and captures the exact moment of the key press.
- Upload to any S3-compatible endpoint (Cloudflare R2, AWS S3, MinIO, …) using AWS Signature V4.
- Copy the public link to the clipboard and show a notification.
- Keep a local copy of every capture.
- A settings window with a "Test Connection" check and an onboarding flow for permissions.
- A codebase whose structure and rules keep it maintainable as an open-source project.

### Non-goals (Phase 1)

- Annotation/editing (Phase 2) and screen recording (Phase 3).
- Other upload destinations (Imgur, FTP, custom HTTP uploaders).
- Auto-update (Sparkle), App Store distribution, localisation beyond English.
- Any telemetry or analytics — never, not only in Phase 1.

## 4. Roadmap

| Phase | Scope | New modules |
|---|---|---|
| 1 | Capture (region / window / full screen), upload, clipboard, notification, history, settings | Core, Capture, Overlay, Upload, Settings, Hotkeys, History, System, Workflow |
| 2 | Editor: arrow, rectangle, text, blur/pixelate, crop — shown between capture and upload (optional per capture) | `SnapboltEditor` |
| 3 | Screen recording of a region to MP4 (optional GIF), then upload | `SnapboltRecording` |

Each phase gets its own spec → plan → implementation cycle. Phases 2 and 3 add modules; they must
not require restructuring Phase 1 modules beyond adding a step to the workflow.

## 5. Platform and stack

| Decision | Choice | ADR |
|---|---|---|
| Language | Swift 6, language mode 6, strict concurrency | [0001](../adr/0001-native-swift-app.md) |
| UI | AppKit for the overlay and menu bar; SwiftUI for settings and onboarding | [0001](../adr/0001-native-swift-app.md) |
| Capture API | ScreenCaptureKit (`SCScreenshotManager`, `SCShareableContent`) | [0007](../adr/0007-freeze-frame-capture.md) |
| Minimum OS | macOS 15 Sequoia | [0005](../adr/0005-macos-15-minimum.md) |
| Storage protocol | S3 API with SigV4, implemented in-house; R2 is the reference target | [0002](../adr/0002-s3-compatible-upload.md) |
| Project layout | Thin app target + local Swift package with one module per responsibility | [0003](../adr/0003-modular-swift-package.md) |
| Project generation | XcodeGen; `.xcodeproj` is generated and never committed | [0004](../adr/0004-xcodegen.md) |
| Global shortcuts | `KeyboardShortcuts` package (MIT) behind our own module | [0006](../adr/0006-dependency-policy-and-keyboardshortcuts.md) |
| Tests | Swift Testing (`import Testing`) | — |
| Lint / format | SwiftLint + swift-format (bundled with the Xcode toolchain) | — |
| Bundle identifier | `io.github.siracozmen01.Snapbolt` | — |
| App type | Agent app (`LSUIElement = YES`): menu bar icon, no Dock icon | — |

Development requires **Xcode 16 or newer** (Swift Testing, `swift format`). The Command Line Tools
alone cannot run the tests.

## 6. Architecture

See [docs/architecture.md](../architecture.md) for the living version of this section.

```
Snapbolt/
├── project.yml                 # XcodeGen spec
├── Makefile                    # bootstrap, project, build, test, lint, format
├── App/                        # thin app target: composition root + menu bar
├── Packages/SnapboltKit/
│   ├── Package.swift
│   ├── Sources/<Module>/
│   └── Tests/<Module>Tests/
└── docs/
```

### Modules

| Module | Responsibility | May import |
|---|---|---|
| `SnapboltCore` | Domain types, protocols, errors, pure geometry/cropping helpers. No UI. | Foundation, CoreGraphics |
| `SnapboltCapture` | Freeze-frame screenshots of all displays, window list, PNG encoding | Core, ScreenCaptureKit, ImageIO |
| `SnapboltOverlay` | Selection UI over the frozen image: region drag, window highlight, magnifier | Core, AppKit |
| `SnapboltUpload` | S3-compatible client: SigV4 signer, `PUT`/`GET`/`DELETE`, connection test | Core, Foundation, CryptoKit |
| `SnapboltSettings` | Preferences model, Keychain storage, settings and onboarding UI (SwiftUI) | Core, SwiftUI, Security |
| `SnapboltHotkeys` | Global shortcut registration and recorder UI (wraps `KeyboardShortcuts`) | Core, KeyboardShortcuts |
| `SnapboltHistory` | Persisted list of the last 10 uploads | Core |
| `SnapboltSystem` | Platform adapters: pasteboard, notifications, file saving, opening URLs, launch at login, permission checks | Core, AppKit, UserNotifications, ServiceManagement |
| `SnapboltWorkflow` | Orchestrates the capture → upload pipeline through Core protocols only | Core |
| App target | Composition root: builds concrete objects, wires them into the workflow; menu bar | Everything |

### Dependency rules

```
App ──► Workflow ──► Core ◄── Capture, Overlay, Upload, Settings, Hotkeys, History, System
 └──────────────► (all feature modules, for construction only)
```

1. `SnapboltCore` depends on no other Snapbolt module.
2. Feature modules depend only on `SnapboltCore`. They never import each other.
3. `SnapboltWorkflow` depends only on `SnapboltCore` and talks to features through protocols.
4. Only the App target imports concrete feature modules, to construct them.
5. These rules are encoded in `Package.swift`; a forbidden import is a build error.
6. Screens that combine features (the settings window) are assembled in the App target from panes
   each module provides; behaviour such as the connection test, permission status and launch at
   login reaches `SnapboltSettings` through Core protocols (`ConnectionTesting`,
   `PermissionChecking`, `LaunchAtLoginControlling`).
7. A test-only target, `SnapboltTestSupport`, holds shared fakes for Core protocols.

## 7. Data flow

### 7.1 Region / window capture (default ⌥⇧4)

1. **Shortcut** — `SnapboltHotkeys` fires `captureRegion`. If an overlay is already open, the press is
   ignored.
2. **Freeze** — `SnapboltCapture` captures every display at native pixel size with
   `SCScreenshotManager` (cursor hidden), and fetches the on-screen window list with frames
   (layer 0, excluding Snapbolt's own windows). Result: `FrozenScreens` (one `CGImage` per display
   plus window metadata).
3. **Select** — `SnapboltOverlay` opens one borderless panel per display showing its frozen image,
   at `.screenSaver` level with `[.canJoinAllSpaces, .fullScreenAuxiliary]` so it also covers apps in
   native full screen. Snapbolt activates itself; the game loses focus and releases the cursor.
   - Drag → region. A magnifier (pixel grid) and the selection size in pixels follow the cursor.
   - Hover → the window under the cursor is highlighted; click → that window's frame.
   - Return → the whole display under the cursor. Escape → cancel.
   - Output: `Selection` = `.region(displayID, rect)` | `.window(displayID, rect)` |
     `.display(displayID)`, with rects in that display's pixel coordinates.
4. **Crop** — `SnapboltCore` crops the frozen image to the selection. No second capture is taken.
   Window captures are crops too, so overlapping windows are included (same as ShareX). A window
   that spans two displays is clipped to the display where it was clicked.
5. **Encode & save** — `SnapboltCapture` encodes PNG. `SnapboltSystem` writes it to
   `~/Pictures/Snapbolt/YYYY-MM/Snapbolt YYYY-MM-DD at HH.mm.ss.png` when local saving is on
   (default on; folder configurable).
6. **Upload** — when storage is configured, `SnapboltUpload` sends the PNG (see §8).
7. **Finish** — on success the public URL goes to the clipboard, the upload is added to history, and a
   notification says "Link copied" (clicking it opens the URL). On failure or when storage is not
   configured, the **image** goes to the clipboard and the notification explains why, with an action
   ("Open Settings"). A capture is never lost.

### 7.2 Full-screen capture (default ⌥⇧3)

Steps 1, 2 (only the display under the cursor), 5, 6 and 7. No overlay.

### 7.3 Concurrency

- Overlay and menu bar run on the main actor. Capture, encoding and upload are `async` and run off
  the main actor.
- Uploads do not block new captures; several uploads may be in flight.
- Cancellation (Escape) ends the workflow silently: no notification, nothing saved.

### 7.4 Menu bar

Items: Capture Region, Capture Full Screen, Recent Uploads (last 10; click copies link), Open
Captures Folder, Settings…, Quit.

### 7.5 First launch

An onboarding window explains and requests Screen Recording and Notification permissions, then
opens the Storage settings. It reappears on launch while Screen Recording is not granted.

## 8. Upload (S3-compatible)

### Settings

| Field | Example | Storage |
|---|---|---|
| Endpoint | `https://<account-id>.r2.cloudflarestorage.com` | UserDefaults |
| Region | `auto` (R2), `eu-central-1` (S3) | UserDefaults |
| Bucket | `screenshots` | UserDefaults |
| Access Key ID | — | UserDefaults |
| Secret Access Key | — | **Keychain** (generic password, service `io.github.siracozmen01.Snapbolt.storage`) |
| Public base URL | `https://i.example.com` or `https://pub-xxxx.r2.dev` | UserDefaults |
| Object key template | `{yyyy}/{MM}/{random}` (default) | UserDefaults |

- Key template tokens: `{yyyy}`, `{MM}`, `{dd}`, `{HH}`, `{mm}`, `{ss}`, `{random}` (10 characters,
  base62, from `SystemRandomNumberGenerator`). The file extension is appended automatically.
- Public URL = public base URL + `/` + object key (each path segment percent-encoded).

### Request

- Path-style addressing: `PUT {endpoint}/{bucket}/{key}`. Works with R2, MinIO and AWS S3.
- Headers: `Content-Type: image/png`, `Cache-Control: public, max-age=31536000, immutable`
  (keys are random and never overwritten), `x-amz-content-sha256` with the real payload hash.
- No ACL header: R2 does not support ACLs; public access is configured on the bucket.
- Signing: AWS Signature Version 4, implemented with CryptoKit, verified against AWS's published
  test vectors.
- Retries: up to 2 retries with exponential backoff (1 s, 2 s) for network errors and HTTP 5xx.
  No retry for 4xx.

### Test Connection

`PUT` a small `snapbolt-connection-test-<random>.txt` → `GET` it through the public base URL →
`DELETE` it. Each step maps failures to a specific message: invalid endpoint, invalid credentials
(`InvalidAccessKeyId`, `SignatureDoesNotMatch`), bucket not found (`NoSuchBucket`), access denied,
public URL not reachable.

## 9. Error handling

- Each domain has its own error type (`CaptureError`, `UploadError`, `SettingsError`,
  `FileSaveError`), conforming to `Error` and `Sendable`, declared in `SnapboltCore` so the workflow
  can map them.
- `SnapboltWorkflow` is the single place that maps errors to a `UserFacingError`
  (title, message, optional recovery action).
- Cancellation is modelled as a result (`Selection?` returning `nil`), not an error.
- Permission loss: a Screen Recording denial during capture opens the onboarding window with a
  button to *System Settings › Privacy & Security › Screen & System Audio Recording*.
- Logging uses `os.Logger` with subsystem `io.github.siracozmen01.Snapbolt` and one category per
  module. Secrets are never logged; URLs and object keys are logged with `privacy: .private`.

Rules: [docs/conventions/error-handling.md](../conventions/error-handling.md).

## 10. Testing

- Swift Testing, one test target per module.
- `SnapboltWorkflow`: every path (success, upload failure, not configured, cancel, permission
  denied) tested with fakes of the Core protocols.
- `SnapboltUpload`: SigV4 against AWS test vectors; request building and error mapping through a
  `URLProtocol` stub. No network in CI. An opt-in integration test runs against a real bucket when
  `SNAPBOLT_IT_ENDPOINT` and related variables are set.
- `SnapboltOverlay` / `SnapboltCore`: coordinate conversion (points ↔ pixels, multiple displays,
  flipped y-axis), crop rects and window hit-testing are pure functions with unit tests.
- ScreenCaptureKit and the overlay window need the Screen Recording permission and cannot run in CI;
  they are covered by the manual checklist in [docs/testing.md](../testing.md).

Rules: [docs/conventions/testing.md](../conventions/testing.md).

## 11. Tooling and CI

- `Makefile` targets: `bootstrap` (installs XcodeGen and SwiftLint via Homebrew), `project`
  (generates the Xcode project), `build`, `test`, `lint`, `format`.
- `.swiftlint.yml` and `.swift-format` implement the limits and rules in
  [docs/conventions](../conventions/README.md), including custom rules for `try?`
  (`no_try_optional`), empty `catch`, `print`, and `TODO` without an issue number.
- GitHub Actions on `macos-15`: generate project, build app, run package tests, SwiftLint
  (`--strict`), `swift format lint --strict`. All must pass before merge.
- Code signing during development uses the developer's own Apple Development certificate (a free
  Apple ID is enough) so the Screen Recording permission survives rebuilds. Ad-hoc signing changes
  the code identity on every build and makes macOS ask for permission again.

## 12. Distribution

- Phase 1: GitHub Releases with a zipped, ad-hoc signed `.app`; README explains the first-launch
  Gatekeeper step. A Homebrew cask follows once a release exists.
- Later: Developer ID signing and notarization if an Apple Developer account is obtained.

## 13. Risks

| Risk | Mitigation |
|---|---|
| A game keeps the cursor captured even after losing focus | Verified in the manual checklist with Minecraft (windowed and full screen). Fallback: full-screen shortcut + crop in Phase 2 editor. |
| Overlay does not appear over native full-screen apps | Panel collection behaviour `.fullScreenAuxiliary`; covered by manual checklist. |
| Retina / mixed-DPI multi-monitor coordinate bugs | Geometry isolated in pure, unit-tested functions; manual checklist covers mixed setups. |
| `KeyboardShortcuts` becomes unmaintained | Wrapped behind `SnapboltHotkeys`; replaceable with Carbon `RegisterEventHotKey` without touching other modules. |

## 14. Acceptance criteria

1. ⌥⇧4 in Minecraft (windowed and full screen) shows the frozen overlay with a free cursor; a
   selected region is uploaded to R2 and its working link is on the clipboard.
2. ⌥⇧3 uploads the display under the cursor.
3. With storage not configured, the image is on the clipboard and saved locally.
4. "Test Connection" reports a specific, correct message for each failure listed in §8.
5. Works on two displays with different scale factors.
6. CI is green: build, tests, SwiftLint strict, swift-format strict.
7. No file exceeds the limits in [docs/conventions/file-organization.md](../conventions/file-organization.md).
