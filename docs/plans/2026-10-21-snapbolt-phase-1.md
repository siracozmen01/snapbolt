# Snapbolt Phase 1 (Capture & Upload) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A menu bar app that freezes the screen on ⌥⇧4 / ⌥⇧3, lets the user select a region or window on the frozen image, saves it locally, uploads it to S3-compatible storage (Cloudflare R2) and puts the public link on the clipboard.

**Architecture:** All code lives in the local Swift package `Packages/SnapboltKit`, one module per responsibility. Feature modules depend only on `SnapboltCore`; `SnapboltWorkflow` orchestrates them through Core protocols; the thin XcodeGen-generated app target in `App/` is the only place that constructs concrete types.

**Tech Stack:** Swift 6 (language mode 6), macOS 15+, AppKit + SwiftUI, ScreenCaptureKit, CryptoKit, Swift Testing, XcodeGen, SwiftLint, swift-format, KeyboardShortcuts (only third-party package).

**Spec:** [docs/specs/2026-10-21-snapbolt-phase-1-design.md](../specs/2026-10-21-snapbolt-phase-1-design.md). Read it, [docs/architecture.md](../architecture.md) and [AGENTS.md](../../AGENTS.md) before starting any task.

## Prerequisites

- Xcode 16 or newer installed and selected: `sudo xcode-select -s /Applications/Xcode.app`. The Command Line Tools alone cannot run the tests (`no such module 'Testing'`).
- Homebrew installed.
- Work on a branch, e.g. `feat/phase-1-capture-upload`; never commit to `main` directly.

## Global Constraints

- Deployment target: macOS **15.0**; `swift-tools-version: 6.0`; Swift language mode 6 for every target.
- Bundle identifier `io.github.siracozmen01.Snapbolt`; logger subsystem identical; one `Logger` per module in `Logging.swift`, category = module name without `Snapbolt` (`"Upload"`).
- Keychain service `io.github.siracozmen01.Snapbolt.storage`.
- Module dependencies exactly as in [architecture.md](../architecture.md#dependency-rules); `KeyboardShortcuts` imported only by `SnapboltHotkeys`.
- Domain error types (`CaptureError`, `UploadError`, `SettingsError`, `FileSaveError`) live in `SnapboltCore`.
- SwiftLint errors: file > 300 lines, type body > 200, function body > 40, cyclomatic complexity > 12, > 7 parameters, line > 140; CI runs `--strict` so warnings (250/150/30/8/5/120) also fail.
- No `!`, `try!`, `as!`, `print`, singletons of our own, GCD, `try?`/empty `catch` without justification, bare `TODO`.
- Every `public` declaration has a `///` doc comment. English only.
- App is an agent app (`LSUIElement = YES`), hardened runtime on, **App Sandbox off** (GitHub distribution, unrestricted capture folder).
- Default shortcuts: region/window **⌥⇧4**, full screen **⌥⇧3**.
- Default object key template `{yyyy}/{MM}/{random}`; `{random}` = 10 base62 characters; extension appended.
- Upload headers: `Content-Type: image/png`, `Cache-Control: public, max-age=31536000, immutable`, `x-amz-content-sha256` = real payload hash; no ACL header; path-style URLs.
- Retries: 2 retries (1 s, 2 s) for network errors and HTTP 5xx; none for 4xx.
- Local copies: `~/Pictures/Snapbolt/YYYY-MM/Snapbolt YYYY-MM-DD at HH.mm.ss.png`, on by default.
- History: last **10** uploads, newest first, `~/Library/Application Support/Snapbolt/history.json`.
- Commits: Conventional Commits, scope = module (`feat(upload): …`), ending with the `Co-Authored-By` trailer when an agent commits.

## Review Focus

1. **Display arrangements with negative origins** (external display left of / above the main one) and mixed scale factors: crops must still match the selection. → Tests in Task 3.
2. **Hand-typed URLs**: endpoint with trailing slash, without scheme, or with the bucket in the path; public base URL with a trailing slash or a path prefix (`https://cdn.example.com/shots/`). → Normalisation tests in Task 10, URL-join tests in Task 2.
3. **Repeated shortcut presses**: a second ⌥⇧4 while the overlay is open is ignored; a capture while a previous upload is still running proceeds. → Tests in Task 4.
4. **Corrupt or missing `history.json`** must not break capture or the menu. → Test in Task 13.
5. **Partially filled storage settings** (e.g. secret key missing from the Keychain) count as "not configured", not as a crash or a confusing upload error. → Test in Task 10.

---

## File Structure

```
Makefile, project.yml, .swiftlint.yml, .swift-format, Config/Signing.xcconfig
.github/workflows/ci.yml, .github/workflows/release.yml
App/
  SnapboltMain.swift                @main; creates NSApplication and the delegate
  AppDelegate.swift                 launch, onboarding check, shortcut → workflow
  AppEnvironment.swift              constructs and wires every concrete dependency
  MenuBar/MenuBarController.swift   NSStatusItem + menu, recent uploads
  Windows/SettingsWindowController.swift, Windows/SettingsRootView.swift
  Windows/OnboardingWindowController.swift
  Resources/Info.plist, Resources/Snapbolt.entitlements
Packages/SnapboltKit/Package.swift
Sources/SnapboltCore/
  Snapbolt.swift                    bundle identifier constant
  Domain/   DisplayID, FrozenDisplay, WindowInfo, FrozenScreens, Selection, CaptureMode,
            CaptureScope, EncodedImage, StorageSettings, CapturePreferences, UploadResult,
            HistoryEntry, UserFacingError, ConnectionTestOutcome
  Errors/   CaptureError, UploadError, SettingsError, FileSaveError
  Protocols/ one file per protocol (12, see Task 2)
  Geometry/ CoordinateConversion.swift, ImageCropper.swift
  Storage/  ObjectKeyTemplate.swift, RandomToken.swift
Sources/SnapboltWorkflow/  CaptureWorkflow.swift, CaptureWorkflow+Dependencies.swift,
                           ErrorPresentation/ErrorPresenter.swift, Logging.swift
Sources/SnapboltUpload/    S3Uploader.swift, S3ConnectionTester.swift, Logging.swift,
                           Signing/SigV4Signer.swift, Signing/CanonicalRequest.swift,
                           Requests/S3Client.swift, Requests/S3ErrorResponse.swift,
                           Requests/RetryPolicy.swift
Sources/SnapboltCapture/   ScreenCaptureKitCapturer.swift, PNGEncoder.swift,
                           WindowListReader.swift, DisplayScaleReader.swift, Logging.swift
Sources/SnapboltOverlay/   OverlayController.swift, Logging.swift,
                           Selection/SelectionTracker.swift, Selection/SelectionResolver.swift,
                           Panels/OverlayPanel.swift, Panels/SelectionView.swift,
                           Panels/SelectionView+Drawing.swift, Panels/MagnifierRenderer.swift
Sources/SnapboltSettings/  SettingsStore.swift, StorageSettingsDraft.swift, Logging.swift,
                           Keychain/SecretStoring.swift, Keychain/KeychainSecretStore.swift,
                           Storage/StorageSettingsModel.swift, Storage/StorageSettingsView.swift,
                           General/GeneralSettingsModel.swift, General/GeneralSettingsView.swift,
                           Onboarding/OnboardingModel.swift, Onboarding/OnboardingView.swift
Sources/SnapboltHotkeys/   HotkeyRegistry.swift, ShortcutNames.swift, ShortcutsSettingsView.swift
Sources/SnapboltHistory/   HistoryStore.swift, Logging.swift
Sources/SnapboltSystem/    PasteboardClipboard.swift, UserNotificationNotifier.swift,
                           LocalCaptureFileSaver.swift, ScreenRecordingPermissionChecker.swift,
                           LaunchAtLoginController.swift, Logging.swift
Sources/SnapboltTestSupport/  fakes for every Core protocol + CGImage.solid(width:height:)
Tests/<Module>Tests/       mirror the source files
```

---

### Task 1: Tooling, package skeleton and CI

Deliverable: an empty but fully wired project — the package graph with every module, an app that shows a menu bar icon with **Quit**, and `make build test lint` green locally and in CI.

**Files:**
- Create: `Makefile`, `project.yml`, `.swiftlint.yml`, `Packages/SnapboltKit/Tests/.swiftlint.yml`, `.swift-format`, `Config/Signing.xcconfig`, `.github/workflows/ci.yml`
- Create: `Packages/SnapboltKit/Package.swift`, `Sources/SnapboltCore/Snapbolt.swift`, `Sources/<each feature module>/Logging.swift`, `Sources/SnapboltTestSupport/TestImages.swift`, `Tests/SnapboltCoreTests/SnapboltTests.swift`
- Create: `App/SnapboltMain.swift`, `App/AppDelegate.swift`, `App/Resources/Info.plist`, `App/Resources/Snapbolt.entitlements`
- Modify: `.gitignore` (add `Config/Signing.local.xcconfig`), `README.md` and `CONTRIBUTING.md` (signing section)

**Interfaces:**
- Produces: `public enum Snapbolt { public static let bundleIdentifier = "io.github.siracozmen01.Snapbolt" }` in Core; in each feature module `let logger = Logger(subsystem: Snapbolt.bundleIdentifier, category: "<Name>")` (internal); in TestSupport `extension CGImage { static func solid(width: Int, height: Int) -> CGImage }`; Make targets `bootstrap project build test lint format`.

- [ ] **Step 1: Write `Package.swift`**

  Platforms `.macOS(.v15)`; one library product `SnapboltKit` listing all non-test targets; dependency `https://github.com/sindresorhus/KeyboardShortcuts` with `.upToNextMinor(from:)` the latest 2.x tag (`git ls-remote --tags` to find it). Targets and dependencies exactly:

  | Target | Depends on |
  |---|---|
  | SnapboltCore | — |
  | SnapboltCapture, SnapboltOverlay, SnapboltUpload, SnapboltSettings, SnapboltHistory, SnapboltSystem, SnapboltWorkflow | SnapboltCore |
  | SnapboltHotkeys | SnapboltCore, KeyboardShortcuts |
  | SnapboltTestSupport | SnapboltCore |
  | SnapboltCoreTests | SnapboltCore, SnapboltTestSupport |

  Each later task adds its own test target (`<Module>Tests` → module + SnapboltTestSupport). Set `swiftLanguageModes: [.v6]`.

- [ ] **Step 2: Write the smoke test** in `Tests/SnapboltCoreTests/SnapboltTests.swift`

  ```swift
  @Test func bundleIdentifierMatchesTheApp() {
      #expect(Snapbolt.bundleIdentifier == "io.github.siracozmen01.Snapbolt")
  }
  ```

- [ ] **Step 3: Run it to see it fail** — `cd Packages/SnapboltKit && swift test` → FAIL, `cannot find 'Snapbolt' in scope`.

- [ ] **Step 4: Add `Snapbolt.swift`, the `Logging.swift` files and `TestImages.swift`**; run `swift test` → PASS.

- [ ] **Step 5: Write `.swift-format`** — version 1, `lineLength: 120`, 4-space indentation, `multiElementCollectionTrailingCommas: true`, `respectsExistingLineBreaks: true`, rule `OrderedImports: true`, `NoBlockComments: true`, `AllPublicDeclarationsHaveDocumentation: true`.

- [ ] **Step 6: Write `.swiftlint.yml`** with the limits from [file-organization.md](../conventions/file-organization.md#size-limits-swiftlint) (`file_length` with `ignore_comment_only_lines: true`), opt-in rules `force_unwrapping`, `implicitly_unwrapped_optional`, `fatal_error_message`, `sorted_imports`, `strict_fileprivate`; disable built-in `todo`; `included: [App, Packages/SnapboltKit/Sources, Packages/SnapboltKit/Tests]`. Custom rules (severity error):

  | Name | Regex | Message |
  |---|---|---|
  | `no_try_optional` | `try\?` | Handle the error or justify with swiftlint:disable:next |
  | `no_empty_catch` | `catch[^{]*\{\s*\}` | A catch must handle, log or rethrow |
  | `no_print` | `\b(print\|NSLog)\(` | Use the module logger |
  | `todo_needs_issue` | `//\s*(TODO\|FIXME)(?!\(#\d+\))` | Write TODO(#issue) |
  | `banned_type_names` | `(class\|struct\|enum\|actor\|protocol)\s+\w*(Manager\|Helper\|Utils\|Utilities\|Common\|Misc)\b` | Name the responsibility |

  `Packages/SnapboltKit/Tests/.swiftlint.yml` disables `force_unwrapping`, `force_try`, `force_cast`, `function_body_length`.

- [ ] **Step 7: Verify each custom rule fires** — create `Sources/SnapboltCore/LintProbe.swift` containing one violation of each custom rule, run `swiftlint --strict` → expect 5 errors, one per rule name. Delete the file, run again → 0 violations.

- [ ] **Step 8: Write `project.yml`, `Config/Signing.xcconfig`, `Info.plist`, entitlements, `AppDelegate.swift`**

  - `project.yml`: project `Snapbolt`, target `Snapbolt` (application, macOS 15.0, sources `App`), local package `SnapboltKit` at `Packages/SnapboltKit`, dependency on product `SnapboltKit`, `PRODUCT_BUNDLE_IDENTIFIER = io.github.siracozmen01.Snapbolt`, `ENABLE_HARDENED_RUNTIME = YES`, `SWIFT_VERSION = 6.0`, `MARKETING_VERSION = 0.1.0`, `CURRENT_PROJECT_VERSION = 1`, `configFiles` for Debug and Release → `Config/Signing.xcconfig`.
  - `Config/Signing.xcconfig`: `CODE_SIGN_STYLE = Automatic`, `CODE_SIGN_IDENTITY = -`, then `#include? "Signing.local.xcconfig"`. A developer creates the git-ignored `Signing.local.xcconfig` with `DEVELOPMENT_TEAM = <their team>` and `CODE_SIGN_IDENTITY = Apple Development` to keep the Screen Recording permission across rebuilds.
  - `Info.plist`: `LSUIElement = YES`, `NSHumanReadableCopyright = "Copyright © 2026 Sirac Ozmen. MIT License."`.
  - `SnapboltMain.swift`: `@main enum SnapboltMain { @MainActor static func main() }` creates `NSApplication.shared`, assigns an `AppDelegate` (kept alive by a local) and calls `run()`. Do not put `@main` on the delegate: without a nib, AppKit never instantiates it.
  - `AppDelegate.swift`: `@MainActor final class AppDelegate: NSObject, NSApplicationDelegate` that creates an `NSStatusItem` with SF Symbol `bolt.fill` and a menu containing only **Quit Snapbolt** (⌘Q). Extended in Task 16.

- [ ] **Step 9: Write the `Makefile`**

  ```make
  bootstrap: ; brew install xcodegen swiftlint
  project:   ; xcodegen generate
  build: project ; xcodebuild -project Snapbolt.xcodeproj -scheme Snapbolt -configuration Debug -destination 'platform=macOS' build
  test:      ; cd Packages/SnapboltKit && swift test $(if $(FILTER),--filter $(FILTER),)
  lint:      ; swiftlint --strict && swift format lint --strict --recursive App Packages/SnapboltKit
  format:    ; swift format --in-place --recursive App Packages/SnapboltKit
  ```

  (Write as conventional multi-line recipes with tabs; `.PHONY` all targets.)

- [ ] **Step 10: Verify locally** — `make bootstrap project build test lint` → `** BUILD SUCCEEDED **`, tests pass, no lint violations. Run the app from Xcode: a bolt icon appears in the menu bar, Quit works, no Dock icon.

- [ ] **Step 11: Write `.github/workflows/ci.yml`** — on `pull_request` and `push` to `main`; `runs-on: macos-15`; steps: checkout, `brew install xcodegen swiftlint`, `make project`, `make build` with `CODE_SIGNING_ALLOWED=NO` appended, `make test`, `make lint`.

- [ ] **Step 12: Update docs** — README "Building from source" and CONTRIBUTING "Setup" step 3: replace "select your team in Signing & Capabilities" with creating `Config/Signing.local.xcconfig` (content shown above). Add `Config/Signing.local.xcconfig` to `.gitignore`.

- [ ] **Step 13: Commit** — `build: add package skeleton, tooling and CI`

---

### Task 2: Core domain types, errors, protocols and object key template

**Files:**
- Create: `Sources/SnapboltCore/Domain/*.swift`, `Errors/*.swift`, `Protocols/*.swift` (one type per file), `Storage/ObjectKeyTemplate.swift`, `Storage/RandomToken.swift`
- Test: `Tests/SnapboltCoreTests/ObjectKeyTemplateTests.swift`, `RandomTokenTests.swift`
- Create: fakes in `Sources/SnapboltTestSupport/` (`FakeScreenCapturer`, `FakeSelectionPresenter`, `FakeImageEncoder`, `SpyLocalCaptureSaver`, `FakeUploader`, `FakeConnectionTester`, `FakeSettingsProvider`, `SpyClipboard`, `SpyNotifier`, `FakeHistoryStore`, `FakePermissionChecker`, `FakeLaunchAtLogin`)
- Test: `Tests/SnapboltCoreTests/FrozenScreensTests.swift`, `StorageSettingsTests.swift`

**Interfaces — Produces** (all `public`, value types `Sendable`, `Equatable` where shown):

```swift
struct DisplayID: Hashable, Sendable { let rawValue: UInt32 }
struct FrozenDisplay: Sendable { let id: DisplayID; let image: CGImage; let frameInGlobalPoints: CGRect; let scale: CGFloat }
struct WindowInfo: Equatable, Sendable { let id: UInt32; let ownerName: String?; let title: String?; let frameInGlobalPoints: CGRect }
struct FrozenScreens: Sendable {
    let displays: [FrozenDisplay]; let windows: [WindowInfo]      // windows front-to-back
    func display(containing pointInGlobalPoints: CGPoint) -> FrozenDisplay?
    func display(withID id: DisplayID) -> FrozenDisplay?
}
enum Selection: Equatable, Sendable { case region(DisplayID, rectInPixels: CGRect); case window(DisplayID, rectInPixels: CGRect); case display(DisplayID) }
enum CaptureMode: Sendable { case region, fullScreen }
enum CaptureScope: Sendable { case allDisplays, displayUnderCursor }
struct EncodedImage: Equatable, Sendable { let data: Data; let contentType: String; let fileExtension: String }
struct StorageSettings: Equatable, Sendable {
    let endpoint: URL; let region: String; let bucket: String; let accessKeyID: String
    let secretAccessKey: String; let publicBaseURL: URL; let keyTemplate: ObjectKeyTemplate
    func publicURL(forObjectKey key: String) -> URL
}
struct CapturePreferences: Equatable, Sendable { let saveLocally: Bool; let folder: URL }
struct UploadResult: Equatable, Sendable { let objectKey: String; let publicURL: URL }
struct HistoryEntry: Codable, Equatable, Sendable { let publicURL: URL; let uploadedAt: Date }
struct UserFacingError: Equatable, Sendable { let title: String; let message: String; let recovery: Recovery? }
enum Recovery: Equatable, Sendable { case openStorageSettings, openPrivacySettings }
enum ConnectionTestOutcome: Equatable, Sendable { case success; case failure(ConnectionTestFailure) }
enum ConnectionTestFailure: Equatable, Sendable {
    case invalidEndpoint, invalidCredentials, bucketNotFound, accessDenied
    case publicURLUnreachable(statusCode: Int?), network(URLError.Code), unexpected(statusCode: Int, code: String?)
    var message: String
}

enum CaptureError: Error, Equatable, Sendable { case permissionDenied, noDisplays, displayNotFound, emptySelection, encodingFailed, captureFailed(String) }
enum UploadError: Error, Equatable, Sendable { case invalidEndpoint(String), network(URLError.Code), server(statusCode: Int, code: String?, message: String?), invalidResponse }
enum SettingsError: Error, Equatable, Sendable { case keychain(status: Int32), invalidEndpoint, invalidPublicBaseURL, missingField(String), invalidKeyTemplate(ObjectKeyTemplate.ValidationError) }
enum FileSaveError: Error, Equatable, Sendable { case folderNotWritable(path: String), writeFailed(path: String) }

protocol ScreenCapturing: Sendable { func freezeDisplays(_ scope: CaptureScope) async throws -> FrozenScreens }
@MainActor protocol SelectionPresenting { func select(on screens: FrozenScreens) async -> Selection? }
protocol ImageEncoding: Sendable { func encodePNG(_ image: CGImage) throws -> EncodedImage }
protocol LocalCaptureSaving: Sendable { func save(_ image: EncodedImage, capturedAt: Date, in folder: URL) throws -> URL }
protocol Uploading: Sendable { func upload(_ image: EncodedImage, using settings: StorageSettings) async throws -> UploadResult }
protocol ConnectionTesting: Sendable { func testConnection(using settings: StorageSettings) async -> ConnectionTestOutcome }
protocol SettingsProviding: Sendable { func storageSettings() async throws -> StorageSettings?; func capturePreferences() async -> CapturePreferences }
@MainActor protocol ClipboardWriting { func writeURL(_ url: URL); func writeImage(_ image: EncodedImage) }
protocol UserNotifying: Sendable { func notifyLinkCopied(_ url: URL) async; func notify(_ error: UserFacingError) async }
protocol UploadHistoryStoring: Sendable { func add(_ entry: HistoryEntry) async throws; func recentEntries() async -> [HistoryEntry] }
protocol PermissionChecking: Sendable { func hasScreenRecordingPermission() -> Bool; func requestScreenRecordingPermission(); func openScreenRecordingSettings(); func requestNotificationPermission() async -> Bool }
@MainActor protocol LaunchAtLoginControlling { var isEnabled: Bool { get }; func setEnabled(_ enabled: Bool) throws }
```

```swift
public struct ObjectKeyTemplate: Equatable, Sendable {
    public enum ValidationError: Error, Equatable, Sendable { case empty, missingRandomToken, unknownToken(String) }
    static let defaultTemplate: ObjectKeyTemplate          // "{yyyy}/{MM}/{random}"
    let rawValue: String
    init(validating raw: String) throws(ValidationError)
    func objectKey(date: Date, random: String, fileExtension: String, timeZone: TimeZone) -> String
}
public enum RandomToken { static func make(length: Int = 10) -> String }   // base62, SystemRandomNumberGenerator
```

If `CGImage` is not `Sendable` in the SDK, wrap it in a `@unchecked Sendable` struct with a comment that `CGImage` is immutable.

`ConnectionTestFailure.message` copy (exact):

| Case | Message |
|---|---|
| invalidEndpoint | The endpoint could not be reached. Check the endpoint URL. |
| invalidCredentials | The access key or secret key is not valid. |
| bucketNotFound | The bucket was not found. Check the bucket name. |
| accessDenied | This key does not have write access to the bucket. |
| publicURLUnreachable(s) | Upload worked, but the public URL returned HTTP *s* / could not be reached (nil). Check the public base URL and that public access is enabled on the bucket. |
| network | Could not connect. Check your internet connection. |
| unexpected(s, c) | Unexpected response: HTTP *s* (*c*). — omit ` (c)` when nil |

- [ ] **Step 1: Write failing tests**

  ```swift
  @Test func findsDisplayContainingPoint() {
      let main = FrozenDisplay(id: .init(rawValue: 1), image: .solid(width: 3024, height: 1964),
                               frameInGlobalPoints: CGRect(x: 0, y: 0, width: 1512, height: 982), scale: 2)
      let left = FrozenDisplay(id: .init(rawValue: 2), image: .solid(width: 1920, height: 1080),
                               frameInGlobalPoints: CGRect(x: -1920, y: 200, width: 1920, height: 1080), scale: 1)
      let screens = FrozenScreens(displays: [main, left], windows: [])
      #expect(screens.display(containing: CGPoint(x: -10, y: 500))?.id == left.id)
      #expect(screens.display(containing: CGPoint(x: 10, y: 10))?.id == main.id)
      #expect(screens.display(containing: CGPoint(x: 5000, y: 0)) == nil)
  }

  @Test(arguments: [
      ("https://i.example.com", "2026/10/a b.png", "https://i.example.com/2026/10/a%20b.png"),
      ("https://i.example.com/", "2026/10/x.png", "https://i.example.com/2026/10/x.png"),
      ("https://cdn.example.com/shots/", "x.png", "https://cdn.example.com/shots/x.png"),
  ])
  func publicURLJoinsBaseAndKey(base: String, key: String, expected: String) { … #expect(settings.publicURL(forObjectKey: key).absoluteString == expected) }

  @Test func expandsTokens() throws {
      let key = try ObjectKeyTemplate(validating: "{yyyy}/{MM}/{dd}/{HH}{mm}{ss}-{random}")
          .objectKey(date: date(2026, 10, 21, 9, 5, 7), random: "abc", fileExtension: "png", timeZone: .gmt)
      #expect(key == "2026/10/21/090507-abc.png")
  }
  @Test(arguments: ["", "{yyyy}/{MM}"]) func rejectsTemplatesWithoutRandom(_ raw: String) { /* .empty for "", .missingRandomToken otherwise */ }
  @Test func rejectsUnknownToken() { #expect(throws: ObjectKeyTemplate.ValidationError.unknownToken("{foo}")) { try ObjectKeyTemplate(validating: "{foo}/{random}") } }
  @Test func randomTokenIsBase62OfRequestedLength() { /* 100 tokens: count == 10, all chars in [A-Za-z0-9], not all equal */ }
  ```

- [ ] **Step 2: Run** `make test FILTER=SnapboltCoreTests` → FAIL (types missing).
- [ ] **Step 3: Implement the types, errors and protocols.** `publicURL` trims trailing `/` from the base, percent-encodes each key segment with the RFC 3986 unreserved set, keeps `/`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Write the fakes** in `SnapboltTestSupport`. Each fake records calls in arrays and returns configurable results. `FakeSelectionPresenter` can either return a stored `Selection?` immediately or suspend until `resume(with:)` is called; `FakeUploader` can likewise suspend until `release()` is called (both needed by Task 4). Fakes holding mutable state are `@MainActor` classes or actors.
- [ ] **Step 6: Commit** — `feat(core): add domain types, errors, protocols and key templates`

---

### Task 3: Core geometry and cropping

**Files:**
- Create: `Sources/SnapboltCore/Geometry/CoordinateConversion.swift`, `Geometry/ImageCropper.swift`
- Test: `Tests/SnapboltCoreTests/CoordinateConversionTests.swift`, `ImageCropperTests.swift`

**Interfaces — Produces:**

```swift
public enum CoordinateConversion {
    /// AppKit global points (origin bottom-left of primary, y up) → pixels of `display` (origin top-left, y down), integral, clamped to the image.
    static func pixelRect(fromGlobalPoints rect: CGRect, on display: FrozenDisplay) -> CGRect
    /// Quartz/CG window bounds (origin top-left of primary, y down, points) → AppKit global points.
    static func globalPointsRect(fromQuartzRect rect: CGRect, primaryDisplayHeight: CGFloat) -> CGRect
    /// AppKit global point → point local to `display` (origin bottom-left of that display).
    static func localPoint(fromGlobalPoint point: CGPoint, on display: FrozenDisplay) -> CGPoint
}
public enum ImageCropper { static func crop(_ screens: FrozenScreens, to selection: Selection) throws(CaptureError) -> CGImage }
```

- [ ] **Step 1: Write failing tests**

  ```swift
  // Retina main display 1512×982 pt, scale 2.
  @Test func convertsRetinaRectToTopLeftPixels() {
      let rect = CoordinateConversion.pixelRect(fromGlobalPoints: CGRect(x: 100, y: 782, width: 50, height: 100), on: main)
      #expect(rect == CGRect(x: 200, y: 200, width: 100, height: 200))
  }
  // External display left of and above the main one: frame (-1920, 982, 1920, 1080), scale 1.
  @Test func convertsRectOnDisplayWithNegativeOrigin() {
      let rect = CoordinateConversion.pixelRect(fromGlobalPoints: CGRect(x: -1900, y: 2000, width: 100, height: 50), on: aboveLeft)
      #expect(rect == CGRect(x: 20, y: 12, width: 100, height: 50))
  }
  @Test func clampsRectToDisplayBounds() { /* rect extending past the right edge → width clipped to image */ }
  @Test func convertsQuartzWindowBoundsToGlobalPoints() {
      #expect(CoordinateConversion.globalPointsRect(fromQuartzRect: CGRect(x: 10, y: 20, width: 300, height: 200), primaryDisplayHeight: 982)
              == CGRect(x: 10, y: 762, width: 300, height: 200))
  }
  @Test func cropsRegionToExactPixelSize() throws { /* .region(main.id, CGRect(x: 10, y: 20, width: 30, height: 40)) → image 30×40 */ }
  @Test func cropsWholeDisplay() throws { /* .display(main.id) → 3024×1964 */ }
  @Test func throwsForUnknownDisplay() { #expect(throws: CaptureError.displayNotFound) { … } }
  @Test func throwsForEmptySelection() { #expect(throws: CaptureError.emptySelection) { … width 0 … } }
  ```

- [ ] **Step 2: Run** `make test FILTER=SnapboltCoreTests` → FAIL.
- [ ] **Step 3: Implement.** `pixelRect`: `x = (r.minX − f.minX)·s`, `y = (f.maxY − r.maxY)·s`, `w = r.width·s`, `h = r.height·s`, then `.integral` and intersect with the image bounds. `crop` uses `CGImage.cropping(to:)`; nil or empty → `.emptySelection`.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(core): add coordinate conversion and cropping`

---

### Task 4: Capture workflow

**Files:**
- Create: `Sources/SnapboltWorkflow/CaptureWorkflow.swift`, `CaptureWorkflow+Dependencies.swift`, `ErrorPresentation/ErrorPresenter.swift`
- Test: `Tests/SnapboltWorkflowTests/CaptureWorkflowTests.swift`, `ErrorPresenterTests.swift` (add the test target)

**Interfaces:**
- Consumes: everything from Task 2; `ImageCropper` from Task 3.
- Produces:

```swift
@MainActor public final class CaptureWorkflow {
    public struct Dependencies {   // all protocol-typed; `now: @Sendable () -> Date`
        capturer, selector, encoder, saver, uploader, settings, clipboard, notifier, history, now
    }
    public init(dependencies: Dependencies)
    public private(set) var isSelecting: Bool
    public func run(_ mode: CaptureMode) async
}
public enum ErrorPresenter { public static func present(_ error: any Error) -> UserFacingError }
```

Behaviour of `run` (spec §7): ignore if `isSelecting`; freeze (`.allDisplays` for `.region`, `.displayUnderCursor` for `.fullScreen`); region → `isSelecting = true` while awaiting `selector`, `nil` → return silently; full screen → `.display(first display)`; crop; encode; if `saveLocally`, save (a save failure is notified but does not stop the upload); `storageSettings()` nil → image to clipboard + notify the not-configured message; else upload → URL to clipboard, history entry `(url, now())`, `notifyLinkCopied`; upload/settings error → image to clipboard + notify `ErrorPresenter.present(error)`; freeze/crop/encode error → notify only. Keep each private step under the function length limit.

`ErrorPresenter` copy (exact; "The image was copied to the clipboard." abbreviated *[clip]*):

| Error | Title | Message | Recovery |
|---|---|---|---|
| not configured (constructed by workflow) | Image copied to clipboard | Set up storage in Settings to get a link instead. | openStorageSettings |
| `CaptureError.permissionDenied` | Screen Recording permission needed | Allow Snapbolt in System Settings › Privacy & Security › Screen & System Audio Recording, then try again. | openPrivacySettings |
| other `CaptureError` | Capture failed | Snapbolt could not capture the screen. Try again. | nil |
| `UploadError.server(_, "InvalidAccessKeyId" \| "SignatureDoesNotMatch", _)` | Upload failed | The access key or secret key is not valid. *[clip]* | openStorageSettings |
| `.server(_, "NoSuchBucket", _)` | Upload failed | The bucket was not found. Check the bucket name. *[clip]* | openStorageSettings |
| `.server(_, "AccessDenied", _)` | Upload failed | This key does not have write access to the bucket. *[clip]* | openStorageSettings |
| other `.server(s, c, _)` | Upload failed | The server returned HTTP *s* (*c*). *[clip]* | openStorageSettings |
| `.network` | Upload failed | Could not reach the storage endpoint. Check your connection. *[clip]* | nil |
| `.invalidEndpoint`, `.invalidResponse` | Upload failed | The storage endpoint is not valid. Check Settings. *[clip]* | openStorageSettings |
| `SettingsError.keychain(status)` | Upload failed | Could not read the secret key from the Keychain (error *status*). *[clip]* | openStorageSettings |
| other `SettingsError` | Upload failed | Storage settings are not valid. Check Settings. *[clip]* | openStorageSettings |
| `FileSaveError` | Could not save the local copy | Check that the captures folder exists and is writable. | nil |
| anything else | Something went wrong | *error.localizedDescription* | nil |

- [ ] **Step 1: Write failing workflow tests** (fakes from TestSupport, one display 100×100 px):

  | Test | Arrange | Expect |
  |---|---|---|
  | `regionCaptureUploadsAndCopiesLink` | selector → `.region(id, 10,10,20,20)`, uploader → URL U | capturer got `.allDisplays`; encoder got 20×20 image; clipboard `writtenURLs == [U]`; history has `(U, fixedNow)`; notifier `linkCopied == [U]` |
  | `cancelledSelectionDoesNothing` | selector → nil | encoder, uploader, clipboard, notifier untouched |
  | `fullScreenSkipsSelection` | mode `.fullScreen` | capturer got `.displayUnderCursor`; selector not called; encoded image 100×100 |
  | `notConfiguredCopiesImage` | settings → nil | no upload; `writtenImages.count == 1`; notified error has recovery `.openStorageSettings` |
  | `uploadFailureCopiesImageAndNotifies` | uploader throws `.server(403, "SignatureDoesNotMatch", nil)` | image on clipboard; notified title "Upload failed" |
  | `keychainFailureCopiesImage` | settings throws `.keychain(status: -25300)` | image on clipboard; message contains "-25300" |
  | `permissionDeniedNotifiesWithPrivacyRecovery` | capturer throws `.permissionDenied` | recovery `.openPrivacySettings`; nothing on clipboard |
  | `secondRegionRunWhileSelectingIsIgnored` | selector suspended; start run A, then `await run(.region)` B | capturer called once; after resuming A with nil, `isSelecting == false` |
  | `captureRunsWhileUploadInFlight` | uploader suspended until released; run A (full screen) in a Task, then run B | capturer called twice; after release both URLs on clipboard |
  | `savesLocallyWhenEnabled` / `skipsLocalSaveWhenDisabled` | prefs saveLocally true/false | saver called once with folder / never |
  | `localSaveFailureStillUploads` | saver throws `.writeFailed` | upload happens; notifier got the save error and the link |

- [ ] **Step 2: Write failing `ErrorPresenterTests`** — one parameterized test over the table above asserting title, message and recovery.
- [ ] **Step 3: Run** `make test FILTER=SnapboltWorkflowTests` → FAIL.
- [ ] **Step 4: Implement** `CaptureWorkflow`, `Dependencies`, `ErrorPresenter`.
- [ ] **Step 5: Run** → PASS. `make lint` → clean.
- [ ] **Step 6: Commit** — `feat(workflow): add capture pipeline and error presentation`

---

### Task 5: SigV4 signer

**Files:**
- Create: `Sources/SnapboltUpload/Signing/SigV4Signer.swift`, `Signing/CanonicalRequest.swift`
- Test: `Tests/SnapboltUploadTests/SigV4SignerTests.swift` (add the test target)

**Interfaces — Produces** (internal):

```swift
struct SigningCredentials: Sendable { let accessKeyID: String; let secretAccessKey: String }
struct SigV4Signer: Sendable {
    let region: String; let service: String          // service "s3"
    /// Returns `request` with `x-amz-date` and `Authorization` set. `payloadHash` is the lowercase hex SHA-256 of the body.
    func sign(_ request: URLRequest, payloadHash: String, credentials: SigningCredentials, date: Date) -> URLRequest
}
```

S3 rule: canonical URI segments are percent-encoded **once** (not twice as other AWS services). Signed headers = `host` plus every header already set on the request, lowercased and sorted; header values trimmed, inner whitespace collapsed.

- [ ] **Step 1: Write failing tests with AWS's published vectors.** Before relying on them, open the sources and confirm the values: [AWS S3 SigV4 header-based auth examples](https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html) and the AWS SigV4 test suite (`get-vanilla`).

  ```swift
  // AWS S3 docs, "GET Object": bucket examplebucket, key /test.txt, Range: bytes=0-9,
  // x-amz-content-sha256 = SHA-256 of empty body, date 20130524T000000Z, region us-east-1.
  @Test func matchesAWSGetObjectExample() {
      let signed = signer.sign(getObjectRequest, payloadHash: emptyHash,
                               credentials: .init(accessKeyID: "AKIAIOSFODNN7EXAMPLE",
                                                  secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"),
                               date: iso("20130524T000000Z"))
      #expect(signed.value(forHTTPHeaderField: "Authorization") ==
          "AWS4-HMAC-SHA256 Credential=AKIAIOSFODNN7EXAMPLE/20130524/us-east-1/s3/aws4_request," +
          "SignedHeaders=host;range;x-amz-content-sha256;x-amz-date," +
          "Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41")
  }
  // AWS test suite get-vanilla: GET / on example.amazonaws.com, service "service",
  // AKIDEXAMPLE / wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY, 20150830T123600Z.
  @Test func matchesGetVanillaVector() { /* Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31 */ }
  @Test func encodesKeySegmentsOnce() { /* key "a b/c+d.png" → canonical URI "/bucket/a%20b/c%2Bd.png" */ }
  ```

  If a vector does not match the source page, fix the test data, never the expectation.

- [ ] **Step 2: Run** `make test FILTER=SnapboltUploadTests` → FAIL.
- [ ] **Step 3: Implement** with CryptoKit `HMAC<SHA256>` and `SHA256`; date formats `yyyyMMdd'T'HHmmss'Z'` and `yyyyMMdd` in UTC, POSIX locale.
- [ ] **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(upload): add SigV4 request signing`

---

### Task 6: S3 client and uploader

**Files:**
- Create: `Sources/SnapboltUpload/S3Uploader.swift`, `Requests/S3Client.swift`, `Requests/S3ErrorResponse.swift`, `Requests/RetryPolicy.swift`
- Test: `Tests/SnapboltUploadTests/S3UploaderTests.swift`, `S3ErrorResponseTests.swift`, `Support/StubURLProtocol.swift`

**Interfaces:**
- Consumes: `SigV4Signer` (Task 5); `Uploading`, `StorageSettings`, `UploadError`, `ObjectKeyTemplate`, `RandomToken` (Tasks 2–3).
- Produces:

```swift
struct S3Client: Sendable {          // internal; reused by Task 7
    init(settings: StorageSettings, session: URLSession, now: @escaping @Sendable () -> Date)
    func put(_ data: Data, key: String, headers: [String: String]) async throws(UploadError)
    func delete(key: String) async throws(UploadError)
}
struct RetryPolicy: Sendable { static let standard = RetryPolicy(delays: [.seconds(1), .seconds(2)]); let delays: [Duration] }
enum S3ErrorResponse { static func parse(_ data: Data) -> (code: String?, message: String?) }   // XMLParser
public final class S3Uploader: Uploading {
    public init(session: URLSession = .shared,
                now: @escaping @Sendable () -> Date = Date.init,
                randomToken: @escaping @Sendable () -> String = { RandomToken.make() },
                sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
                timeZone: TimeZone = .current)
}
```

- [ ] **Step 1: Write `StubURLProtocol`** — a `URLProtocol` subclass whose handler `(URLRequest) -> (HTTPURLResponse, Data)` or thrown `URLError` is stored behind an `NSLock` (comment why `@unchecked Sendable` is safe); records requests including body (read `httpBodyStream`). Suites using it are `.serialized`.
- [ ] **Step 2: Write failing tests**

  | Test | Expect |
  |---|---|
  | `putsToPathStyleURLWithHeaders` | one `PUT https://acc.r2.cloudflarestorage.com/shots/2026/10/abcdefghij.png`; headers `Content-Type: image/png`, `Cache-Control: public, max-age=31536000, immutable`, `x-amz-content-sha256` = SHA-256 hex of body, `Authorization` starts with `AWS4-HMAC-SHA256 Credential=KEY/` and contains `/auto/s3/aws4_request`; no `x-amz-acl` |
  | `returnsPublicURLFromBaseURL` | result `publicURL == https://i.example.com/2026/10/abcdefghij.png`, `objectKey == "2026/10/abcdefghij.png"` |
  | `retriesServerErrorsThenSucceeds` | stub 500, 503, 200 → success; 3 requests; recorded sleeps `[1s, 2s]` |
  | `givesUpAfterTwoRetries` | 500 ×3 → throws `.server(statusCode: 500, …)`; 3 requests |
  | `doesNotRetryClientErrors` | 403 with `<Error><Code>SignatureDoesNotMatch</Code><Message>m</Message></Error>` → throws `.server(403, "SignatureDoesNotMatch", "m")`; 1 request |
  | `retriesNetworkErrors` | `URLError(.notConnectedToInternet)` ×3 → throws `.network(.notConnectedToInternet)`; 3 requests |
  | `parsesS3ErrorXML` / `toleratesNonXMLBody` | code/message parsed / both nil |

- [ ] **Step 3: Run** `make test FILTER=SnapboltUploadTests` → FAIL.
- [ ] **Step 4: Implement.** The uploader builds the key with `settings.keyTemplate.objectKey(date: now(), random: randomToken(), fileExtension: image.fileExtension, timeZone:)`. Check `Task.checkCancellation()` before each retry.
- [ ] **Step 5: Run** → PASS.
- [ ] **Step 6: Opt-in integration test** — `S3UploaderIntegrationTests` enabled only when all `SNAPBOLT_IT_*` variables from [conventions/testing.md](../conventions/testing.md#integration-tests) are set: upload a 1×1 PNG, `GET` the public URL → 200, then delete the object. Run once against a real R2 bucket if available; record the result in the PR.
- [ ] **Step 7: Commit** — `feat(upload): add S3-compatible uploader with retries`

---

### Task 7: Connection tester

**Files:**
- Create: `Sources/SnapboltUpload/S3ConnectionTester.swift`
- Test: `Tests/SnapboltUploadTests/S3ConnectionTesterTests.swift`

**Interfaces:**
- Consumes: `S3Client` (Task 6), `ConnectionTesting`, `ConnectionTestOutcome` (Task 2).
- Produces: `public struct S3ConnectionTester: ConnectionTesting { public init(session: URLSession = .shared, now: …, randomToken: …) }`.

Sequence: `PUT snapbolt-connection-test-<random>.txt` (text/plain, body `Snapbolt connection test`) → unsigned `GET` of its public URL → `DELETE` (best-effort; justified `try?`). Mapping: PUT `.network(.cannotFindHost | .cannotConnectToHost | .badURL)` → `.invalidEndpoint`; other `.network(c)` → `.network(c)`; `InvalidAccessKeyId`/`SignatureDoesNotMatch` → `.invalidCredentials`; `NoSuchBucket` → `.bucketNotFound`; `AccessDenied` → `.accessDenied`; other server → `.unexpected`; GET non-2xx → `.publicURLUnreachable(statusCode:)`, GET network error → `.publicURLUnreachable(statusCode: nil)`.

- [ ] **Step 1: Write failing tests** — one per mapping row above plus `succeedsWhenAllStepsWork` (expects PUT, GET, DELETE in that order) and `deletesEvenWhenPublicURLFails` (DELETE still sent).
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(upload): add storage connection test`

---

### Task 8: Screen capture and PNG encoding

**Files:**
- Create: `Sources/SnapboltCapture/ScreenCaptureKitCapturer.swift`, `PNGEncoder.swift`, `WindowListReader.swift`, `DisplayScaleReader.swift`
- Test: `Tests/SnapboltCaptureTests/PNGEncoderTests.swift`

**Interfaces:**
- Consumes: `ScreenCapturing`, `ImageEncoding`, `FrozenScreens`, `CaptureError`, `CoordinateConversion` (Tasks 2–3).
- Produces: `public struct ScreenCaptureKitCapturer: ScreenCapturing { public init(excludingBundleID: String = Snapbolt.bundleIdentifier) }`, `public struct PNGEncoder: ImageEncoding { public init() }`.

Approach: `SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)`; per display (all, or the one whose frame contains `NSEvent.mouseLocation` for `.displayUnderCursor`) capture in parallel with `withThrowingTaskGroup` using `SCScreenshotManager.captureImage(contentFilter: SCContentFilter(display:excludingWindows: []), configuration:)`, configuration `width/height = points × backingScaleFactor`, `showsCursor = false`, `captureResolution = .best`. Scale and AppKit frame come from the `NSScreen` whose `NSScreenNumber` equals the display ID (`DisplayScaleReader`). Windows come from `CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)` (front-to-back), keeping layer 0, width and height ≥ 40, owner bundle ≠ ours, converted with `globalPointsRect(fromQuartzRect:primaryDisplayHeight:)` (`WindowListReader`). Map `SCStreamError.userDeclined` and `CGPreflightScreenCaptureAccess() == false` to `.permissionDenied`; no displays → `.noDisplays`.

- [ ] **Step 1: Write failing PNG tests** — `encodesPNGWithSignatureAndSize`: encode `CGImage.solid(width: 7, height: 5)` → data starts with `89 50 4E 47 0D 0A 1A 0A`, `contentType == "image/png"`, `fileExtension == "png"`, decoding with `CGImageSourceCreateWithData` gives 7×5.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement `PNGEncoder`** (ImageIO `CGImageDestination`, failure → `.encodingFailed`). **Step 4: Run** → PASS.
- [ ] **Step 5: Implement the capturer, `WindowListReader`, `DisplayScaleReader`.** These need the Screen Recording permission and are verified in Task 16.
- [ ] **Step 6: Run** `make build lint` → clean.
- [ ] **Step 7: Commit** — `feat(capture): add freeze-frame capture and PNG encoding`

---

### Task 9: Selection logic (pure)

**Files:**
- Create: `Sources/SnapboltOverlay/Selection/SelectionTracker.swift`, `Selection/SelectionResolver.swift`
- Test: `Tests/SnapboltOverlayTests/SelectionTrackerTests.swift`, `SelectionResolverTests.swift`

**Interfaces — Produces** (internal; all points are AppKit global points):

```swift
enum TrackerOutcome: Equatable { case region(CGRect, anchor: CGPoint); case window(WindowInfo, anchor: CGPoint) }
struct SelectionTracker {
    static let clickThreshold: CGFloat = 4
    init(windows: [WindowInfo])
    private(set) var currentRegion: CGRect?          // normalised, during a drag
    private(set) var highlightedWindow: WindowInfo?
    mutating func mouseMoved(to point: CGPoint)
    mutating func mouseDown(at point: CGPoint)
    mutating func mouseDragged(to point: CGPoint)
    mutating func mouseUp(at point: CGPoint) -> TrackerOutcome?
}
enum SelectionResolver {
    static func selection(for outcome: TrackerOutcome, in screens: FrozenScreens) -> Selection?
    static func fullDisplaySelection(at point: CGPoint, in screens: FrozenScreens) -> Selection?
}
```

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `dragProducesNormalisedRegion` | down (100,100) → drag (40,160) → up → `.region(CGRect(x:40,y:100,w:60,h:60), anchor: (100,100))` |
  | `clickSelectsFrontmostWindowUnderCursor` | two overlapping windows; click inside both → the first (front) one |
  | `clickOnEmptyDesktopKeepsOverlayOpen` | up returns nil |
  | `tinyDragCountsAsClick` | drag of 3 pt over a window → `.window` |
  | `hoverHighlightsWindowAndClearsDuringDrag` | `highlightedWindow` set on move, nil while dragging |
  | `regionIsClippedToAnchorDisplay` | region crossing from main to the left display → `.region(main.id, …)` clipped to main |
  | `windowSpanningDisplaysIsClippedToClickedDisplay` | `.window(left.id, rect within left)` |
  | `returnKeySelectsDisplayUnderCursor` | `fullDisplaySelection(at:)` → `.display(id)` |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** (resolver uses `CoordinateConversion.pixelRect`; empty rect after clipping → nil). **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(overlay): add selection tracking and resolution`

---

### Task 10: Settings store and Keychain

**Files:**
- Create: `Sources/SnapboltSettings/SettingsStore.swift`, `StorageSettingsDraft.swift`, `Keychain/SecretStoring.swift`, `Keychain/KeychainSecretStore.swift`
- Test: `Tests/SnapboltSettingsTests/StorageSettingsDraftTests.swift`, `SettingsStoreTests.swift`, `Support/InMemorySecretStore.swift`

**Interfaces — Produces:**

```swift
protocol SecretStoring: Sendable {        // internal
    func secret(for account: String) throws(SettingsError) -> String?
    func setSecret(_ secret: String, for account: String) throws(SettingsError)
    func deleteSecret(for account: String) throws(SettingsError)
}
struct KeychainSecretStore: SecretStoring      // generic password, service io.github.siracozmen01.Snapbolt.storage
public struct StorageSettingsDraft: Equatable, Sendable {
    public var endpoint, region, bucket, accessKeyID, secretAccessKey, publicBaseURL, keyTemplate: String
    public var isComplete: Bool                     // every field non-empty after trimming
    public func validated() throws(SettingsError) -> StorageSettings
}
public struct SettingsStore: SettingsProviding {
    public init(defaults: UserDefaults = .standard)                  // uses KeychainSecretStore
    init(defaults: UserDefaults, secrets: any SecretStoring)         // tests
    public func loadDraft() throws(SettingsError) -> StorageSettingsDraft
    public func save(_ settings: StorageSettings) throws(SettingsError)
    public func saveCapturePreferences(_ preferences: CapturePreferences)
}
```

UserDefaults keys: `storage.endpoint`, `storage.region` (default `auto`), `storage.bucket`, `storage.accessKeyID`, `storage.publicBaseURL`, `storage.keyTemplate` (default `{yyyy}/{MM}/{random}`), `capture.saveLocally` (default true), `capture.folderPath` (default `~/Pictures/Snapbolt`). Keychain account = `"secretAccessKey"`. `storageSettings()` returns nil when the draft is incomplete, otherwise `try draft.validated()`. `SettingsStore` must be `Sendable`; if the SDK does not mark `UserDefaults` as `Sendable`, store it in an `@unchecked Sendable` box with a comment (UserDefaults is documented as thread-safe).

Validation: trim all fields; endpoint must parse as `https` URL with a host; a path other than `/` → `.invalidEndpoint`; a missing scheme gets `https://` prepended; trailing `/` removed. Public base URL: `http` or `https` with a host, path allowed, trailing `/` removed, else `.invalidPublicBaseURL`. Key template via `ObjectKeyTemplate(validating:)` → `.invalidKeyTemplate`.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `normalisesEndpointWithoutSchemeAndTrailingSlash` | `"acc.r2.cloudflarestorage.com/"` → `https://acc.r2.cloudflarestorage.com` |
  | `rejectsEndpointWithBucketInPath` | `"https://acc.r2.cloudflarestorage.com/shots"` → `.invalidEndpoint` |
  | `rejectsHTTPEndpoint` | `"http://…"` → `.invalidEndpoint` |
  | `keepsPublicBaseURLPathWithoutTrailingSlash` | `"https://cdn.example.com/shots/"` → `https://cdn.example.com/shots` |
  | `rejectsInvalidKeyTemplate` | `"{yyyy}"` → `.invalidKeyTemplate(.missingRandomToken)` |
  | `roundTripsSettingsThroughStore` | save then `storageSettings()` equal; secret only in the secret store, not in defaults |
  | `missingSecretMeansNotConfigured` | all defaults set, secret store empty → `storageSettings() == nil` |
  | `freshStoreHasDefaults` | draft region `auto`, template default; preferences saveLocally true, folder `~/Pictures/Snapbolt` |
  | `keychainErrorPropagates` | secret store throws `.keychain(status: -25293)` → `storageSettings()` throws it |

  Use `UserDefaults(suiteName: "test-\(UUID())")`.

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(settings): add settings store with Keychain secrets`

---

### Task 11: Settings and onboarding UI

**Files:**
- Create: `Sources/SnapboltSettings/Storage/StorageSettingsModel.swift`, `Storage/StorageSettingsView.swift`, `General/GeneralSettingsModel.swift`, `General/GeneralSettingsView.swift`, `Onboarding/OnboardingModel.swift`, `Onboarding/OnboardingView.swift`
- Test: `Tests/SnapboltSettingsTests/StorageSettingsModelTests.swift`, `GeneralSettingsModelTests.swift`, `OnboardingModelTests.swift`

**Interfaces — Produces** (`@MainActor @Observable public final class` models; views take their model):

```swift
StorageSettingsModel(store: SettingsStore, tester: any ConnectionTesting)
    var draft: StorageSettingsDraft; var validationMessage: String?; var testStatus: TestStatus
    enum TestStatus: Equatable { case idle, testing, succeeded, failed(String) }
    func save() -> Bool;  func testConnection() async
GeneralSettingsModel(store: SettingsStore, launchAtLogin: any LaunchAtLoginControlling)
    var saveLocally: Bool; var folder: URL; var launchAtLoginEnabled: Bool; var errorMessage: String?
OnboardingModel(permissions: any PermissionChecking, onFinish: @MainActor () -> Void)
    var hasScreenRecordingPermission: Bool; func refresh(); func grantScreenRecording(); func requestNotifications() async; func finish()
public struct StorageSettingsView: View, GeneralSettingsView: View, OnboardingView: View
```

Validation messages (exact): `.invalidEndpoint` → "Endpoint must be an https URL without a path, e.g. https://<account-id>.r2.cloudflarestorage.com"; `.invalidPublicBaseURL` → "Public base URL must be an http(s) URL, e.g. https://i.example.com"; `.invalidKeyTemplate(.missingRandomToken)` → "The key template must contain {random}."; `.invalidKeyTemplate(.unknownToken(t))` → "Unknown token t."; `.missingField(f)` → "f is required.". `testConnection` validates first (failure → `.failed(validationMessage)`), then maps `.success` → `.succeeded`, `.failure(f)` → `.failed(f.message)`. The folder picker uses SwiftUI `.fileImporter` with `allowedContentTypes: [.folder]`. Views stay under ~30-line bodies by extracting subviews.

- [ ] **Step 1: Write failing model tests** — `saveRejectsInvalidEndpointWithMessage`, `savePersistsValidDraft`, `testConnectionReportsSuccess`, `testConnectionReportsFailureMessage` (fake → `.bucketNotFound` → `.failed("The bucket was not found. Check the bucket name.")`), `testConnectionValidatesFirst` (tester not called), `togglingLaunchAtLoginCallsController`, `launchAtLoginErrorShowsMessage`, `onboardingRefreshReadsPermission`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement models, then views.** **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(settings): add storage, general and onboarding screens`

---

### Task 12: Global shortcuts

**Files:**
- Create: `Sources/SnapboltHotkeys/ShortcutNames.swift`, `HotkeyRegistry.swift`, `ShortcutsSettingsView.swift`
- Test: `Tests/SnapboltHotkeysTests/ShortcutNamesTests.swift`

**Interfaces — Produces:**

```swift
extension KeyboardShortcuts.Name { static let captureRegion, captureFullScreen }   // internal
@MainActor public final class HotkeyRegistry {
    public init(onCapture: @escaping @MainActor (CaptureMode) -> Void)
    public func start()                   // registers KeyboardShortcuts.onKeyUp for both names
}
public struct ShortcutsSettingsView: View  // two KeyboardShortcuts.Recorder rows: "Capture Region or Window", "Capture Full Screen"
```

- [ ] **Step 1: Write failing test** — `defaultShortcutsMatchSpec`: `captureRegion.defaultShortcut == .init(.four, modifiers: [.option, .shift])`, `captureFullScreen.defaultShortcut == .init(.three, modifiers: [.option, .shift])`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(hotkeys): add global capture shortcuts`

---

### Task 13: Upload history

**Files:**
- Create: `Sources/SnapboltHistory/HistoryStore.swift`
- Test: `Tests/SnapboltHistoryTests/HistoryStoreTests.swift`

**Interfaces — Produces:** `public actor HistoryStore: UploadHistoryStoring { public init(fileURL: URL, limit: Int = 10); public static func defaultFileURL() throws -> URL }` (`~/Library/Application Support/Snapbolt/history.json`, directory created on first write). Loads lazily on first access; JSON with ISO 8601 dates; atomic writes.

- [ ] **Step 1: Write failing tests** (temporary directory) — `newestFirst`, `keepsOnlyTen` (add 12 → 10, oldest two gone), `persistsAcrossInstances`, `missingFileMeansEmpty`, `corruptFileMeansEmptyAndIsReplacedOnAdd` (write `"not json"` → `recentEntries() == []`; `add` succeeds; a new instance reads 1 entry).
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement** (corrupt file logged at `.error`). **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** — `feat(history): persist recent uploads`

---

### Task 14: System adapters

**Files:**
- Create: `Sources/SnapboltSystem/PasteboardClipboard.swift`, `UserNotificationNotifier.swift`, `LocalCaptureFileSaver.swift`, `ScreenRecordingPermissionChecker.swift`, `LaunchAtLoginController.swift`
- Test: `Tests/SnapboltSystemTests/LocalCaptureFileSaverTests.swift`

**Interfaces — Produces:**

```swift
@MainActor public final class PasteboardClipboard: ClipboardWriting { public init(pasteboard: NSPasteboard = .general) }
public final class UserNotificationNotifier: NSObject, UserNotifying, UNUserNotificationCenterDelegate {
    public init(onRecovery: @escaping @MainActor @Sendable (Recovery) -> Void)
}   // banner even when active; click on link notification opens the URL; click on error opens its recovery
public struct LocalCaptureFileSaver: LocalCaptureSaving { public init(timeZone: TimeZone = .current) }
public struct ScreenRecordingPermissionChecker: PermissionChecking { public init() }
@MainActor public final class LaunchAtLoginController: LaunchAtLoginControlling { public init() }   // SMAppService.mainApp
```

Clipboard: `writeURL` sets both `.string` and `.URL`; `writeImage` sets `.png` data. Notifier: link notification title "Link copied", body = URL string; error notification title/body from `UserFacingError`; URL and recovery stored in `userInfo`. Permission checker: `CGPreflightScreenCaptureAccess`, `CGRequestScreenCaptureAccess`, opens `x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`. File saver: path `<folder>/YYYY-MM/Snapbolt YYYY-MM-DD at HH.mm.ss.png`, creates directories, never overwrites (append ` (2)`, ` (3)`, …), maps failures to `FileSaveError`.

- [ ] **Step 1: Write failing saver tests** — `savesIntoMonthFolderWithTimestampName` (date 2026-10-21 14:03:07 GMT → `2026-10/Snapbolt 2026-10-21 at 14.03.07.png`, bytes equal), `doesNotOverwriteExistingFile` (second save → `… 14.03.07 (2).png`), `reportsUnwritableFolder` (folder is a file → `.folderNotWritable`).
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement all adapters.** **Step 4: Run** → PASS; `make lint` clean.
- [ ] **Step 5: Commit** — `feat(system): add clipboard, notification, file and permission adapters`

---

### Task 15: Overlay UI

**Files:**
- Create: `Sources/SnapboltOverlay/OverlayController.swift`, `Panels/OverlayPanel.swift`, `Panels/SelectionView.swift`, `Panels/SelectionView+Drawing.swift`, `Panels/MagnifierRenderer.swift`

**Interfaces:**
- Consumes: `SelectionTracker`, `SelectionResolver` (Task 9); `SelectionPresenting`, `FrozenScreens`, `CoordinateConversion` (Tasks 2–3).
- Produces: `@MainActor public final class OverlayController: SelectionPresenting { public init() }`.

Approach: one `OverlayPanel` (`NSPanel`, borderless, `level = .screenSaver`, `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]`, `canBecomeKey` true, `isOpaque`, no shadow) per frozen display, framed to `frameInGlobalPoints`; `NSApp.activate()` then `makeKeyAndOrderFront`. `select(on:)` suspends on a `CheckedContinuation` resumed exactly once by mouse-up outcome, Return (`fullDisplaySelection`) or Escape (nil), then closes every panel and releases the images. `SelectionView` draws the frozen image, a 40 % black dim outside the selection/highlight, a 1 pt white border, the size label in pixels (`"W × H"`), and the magnifier (`MagnifierRenderer`: 11×11 source pixels at 10×, crosshair, placed beside the cursor, flipped to stay on screen). Cursor: `NSCursor.crosshair`.

- [ ] **Step 1: Implement.** **Step 2:** `make build lint` → clean. Behaviour is verified in Task 16.
- [ ] **Step 3: Commit** — `feat(overlay): add frozen-screen selection overlay`

---

### Task 16: App composition, menu bar and windows

**Files:**
- Create: `App/AppEnvironment.swift`, `App/MenuBar/MenuBarController.swift`, `App/Windows/SettingsWindowController.swift`, `App/Windows/SettingsRootView.swift`, `App/Windows/OnboardingWindowController.swift`
- Modify: `App/AppDelegate.swift`

**Interfaces:**
- Consumes: every public type from Tasks 2–15.
- Produces: the running app.

Behaviour: `AppEnvironment` constructs `SettingsStore`, `S3Uploader`, `S3ConnectionTester`, `ScreenCaptureKitCapturer`, `PNGEncoder`, `LocalCaptureFileSaver`, `OverlayController`, `PasteboardClipboard`, `UserNotificationNotifier(onRecovery:)`, `HistoryStore(fileURL: .defaultFileURL())`, `ScreenRecordingPermissionChecker`, `LaunchAtLoginController`, `CaptureWorkflow`, `HotkeyRegistry`. Recovery `.openStorageSettings` → settings window on the Storage tab; `.openPrivacySettings` → permission checker. A shortcut or menu item starts `Task { await workflow.run(mode); await menuBar.refreshRecentUploads() }`. Menu: Capture Region (⌥⇧4 shown), Capture Full Screen (⌥⇧3), Recent Uploads ▸ (last 10 by time, click copies link; "No uploads yet" disabled when empty), Open Captures Folder, Settings… (⌘,), Quit Snapbolt (⌘Q). `SettingsRootView` = `TabView` with Storage, General, Shortcuts tabs. On launch, onboarding opens when Screen Recording is not granted; Finish opens settings on Storage.

- [ ] **Step 1: Implement.** **Step 2:** `make build test lint` → all green.
- [ ] **Step 3: Manual verification** — with `Config/Signing.local.xcconfig` set, run the app and work through every section of [docs/testing.md](../testing.md) against a real R2 bucket, including Minecraft windowed and full screen. Fix defects in the owning module with a test where the defect is in logic. Record the ticked checklist in the PR.
- [ ] **Step 4: Commit** — `feat(app): wire modules into the menu bar app`

---

### Task 17: Release workflow and docs

**Files:**
- Create: `.github/workflows/release.yml`
- Modify: `README.md` (status, install, first-launch Gatekeeper step), `CHANGELOG.md`, `docs/architecture.md` (only if anything drifted)

- [ ] **Step 1: Write `release.yml`** — on tags `v*`, `macos-15`: `make project`; `xcodebuild -configuration Release CODE_SIGN_IDENTITY=- archive`/build into `build/`; `ditto -c -k --keepParent build/…/Snapbolt.app Snapbolt-${tag}.zip`; `gh release create "$tag" Snapbolt-${tag}.zip --generate-notes` with `GITHUB_TOKEN`.
- [ ] **Step 2: Update README** — replace the "early development" note with install steps: download the zip from Releases, move to Applications, first launch via right-click → Open (or System Settings › Privacy & Security › Open Anyway), grant Screen Recording. Keep the R2 guide.
- [ ] **Step 3: Update CHANGELOG** — Unreleased → Added: region/window/full-screen capture with freeze frame, S3/R2 upload, clipboard link, notifications, recent uploads, local copies, settings with connection test, onboarding.
- [ ] **Step 4: Check docs against code** — module list, dependency graph and file layout in `docs/architecture.md` match `Package.swift` and the tree; fix any drift.
- [ ] **Step 5:** `make lint` → clean. **Commit** — `ci: add release workflow` and `docs: update README and changelog for 0.1.0`
