# Naming

Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/):
clarity at the point of use beats brevity. The rules below are additions.

## Types

| Kind | Convention | Examples |
|---|---|---|
| Struct, class, enum, actor | `UpperCamelCase` noun | `FrozenScreens`, `S3Uploader`, `Selection` |
| Protocol describing a capability | `-ing` / `-able` | `ScreenCapturing`, `Uploading`, `ClipboardWriting` |
| Protocol describing a thing | noun | `UploadDestination` |
| Error type | `<Domain>Error` | `CaptureError`, `UploadError` |
| SwiftUI view | `<Thing>View` | `StorageSettingsView` |
| AppKit view / panel / controller | `<Thing>View`, `<Thing>Panel`, `<Thing>Controller` | `SelectionView`, `OverlayPanel` |
| Observable model for a view | `<Thing>Model` | `StorageSettingsModel` |
| Test double | `Fake<Protocol subject>`, `Stub…`, `Spy…` | `FakeUploader`, `SpyClipboard` |

Concrete implementations are named after **how** they do it, protocols after **what**:
`Uploading` ← `S3Uploader`; `ScreenCapturing` ← `ScreenCaptureKitCapturer`.

## Banned names

These names attract unrelated code and grow into god files. Do not use them for types or files:

`Manager`, `Helper`, `Utils`, `Utilities`, `Common`, `Misc`, `Stuff`, `Handler` (alone), `Base`
(as a prefix for superclasses), `Service` (alone).

Name the actual responsibility instead: not `CaptureManager` but `ScreenCaptureKitCapturer` and
`CaptureWorkflow`; not `StringUtils` but an extension in `String+ObjectKey.swift`.

## Functions and properties

- `lowerCamelCase`. Functions with side effects are verbs (`upload(_:)`, `save(_:to:)`); pure
  functions returning a value read as nouns or `-ed`/`-ing` forms (`cropped(to:)`, `distance(to:)`).
- Booleans read as assertions: `isConfigured`, `hasScreenRecordingPermission`, `shouldSaveLocally`.
- Async functions are not suffixed with `Async`.
- Factory methods start with `make`: `makeOverlayPanel(for:)`.
- No abbreviations except widely known ones: `URL`, `ID`, `PNG`, `HTTP`, `S3`, `UI`. Acronyms are
  uniformly cased: `publicURL`, `displayID`, `URLRequest`.
- Units in names where ambiguous: `timeoutSeconds`, `rectInPixels`, `frameInGlobalPoints`
  (see the coordinate spaces in [architecture.md](../architecture.md#coordinate-spaces)).

## Files and folders

- A file is named after its primary type: `S3Uploader.swift`.
- Extensions adding a conformance: `S3Uploader+Uploading.swift`.
- Extensions on types we do not own: `<Type>+<Purpose>.swift`, e.g. `CGRect+Pixels.swift`.
- Folders inside a module group by feature, not by kind: `Signing/`, `Requests/` — not `Models/`,
  `Extensions/`, `Protocols/`.
- Test files mirror source files: `S3Uploader.swift` → `S3UploaderTests.swift`.

## Modules

`Snapbolt<Responsibility>`, singular, one word where possible: `SnapboltUpload`, not
`SnapboltUploads` or `SnapboltUploadService`.
