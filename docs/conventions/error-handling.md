# Error handling

## Principles

1. **Errors are typed per domain and declared in `SnapboltCore`.** Each domain has an
   `enum <Domain>Error: Error, Sendable` (`CaptureError`, `UploadError`, `SettingsError`,
   `FileSaveError`) with cases that carry the information needed to act on them. They live in Core,
   next to the protocol whose contract they belong to, because `SnapboltWorkflow` can import only
   Core and must be able to map every error. Errors that never leave a module (e.g. a parser's
   internal failure) stay private to that module and are converted before crossing the boundary.
2. **Errors are not swallowed.** Every error is either handled (with a decision recorded in code)
   or propagated.
3. **One place turns errors into messages.** Feature modules throw domain errors;
   `SnapboltWorkflow` maps them to `UserFacingError`. Views and notifications show only
   `UserFacingError`.
4. **Cancellation is not an error.** A user pressing Escape returns `nil`, not a thrown error.
5. **Nothing the user captured is ever lost** because of an error (see the fallback in the
   Phase 1 spec).

## Error types

```swift
public enum UploadError: Error, Sendable, Equatable {
    case notConfigured
    case invalidEndpoint(String)
    case network(URLError.Code)
    case server(statusCode: Int, code: String?, message: String?)   // S3 XML error body
}
```

- Prefer specific cases over a generic `case unknown(Error)`. If an underlying error must be kept,
  store the part that matters (`URLError.Code`), not `any Error`, so the type stays `Sendable` and
  `Equatable`.
- Use typed throws (`throws(UploadError)`) for module-internal functions where it clarifies the
  contract; public protocol requirements use plain `throws`.

## `try?`, `try!` and empty `catch`

- `try!` is banned outside tests.
- `try?` is allowed only when failure genuinely does not matter, with a comment saying why. A
  custom SwiftLint rule flags it; the justification goes in the disable comment:

  ```swift
  // swiftlint:disable:next no_try_optional - deleting the connection-test object is best-effort
  try? await client.delete(key)
  ```

- Empty `catch {}` blocks fail SwiftLint. A `catch` must handle, log, or rethrow.

## User-facing errors

```swift
public struct UserFacingError: Sendable, Equatable {
    public let title: String          // "Upload failed"
    public let message: String        // "The access key is not valid for this bucket."
    public let recovery: Recovery?    // .openStorageSettings, .openPrivacySettings
}
```

- Messages say what happened and what to do, in plain language. No status codes or stack traces in
  the title; details may go into the message when they help ("HTTP 403: SignatureDoesNotMatch").
- Mapping lives in `SnapboltWorkflow/ErrorPresentation/` and is unit tested case by case.

## Preconditions

`precondition` / `preconditionFailure` are for programmer errors (impossible states), never for
conditions the user or the network can cause. Always include a message explaining the invariant.

## Logging

- `os.Logger`, subsystem `io.github.siracozmen01.Snapbolt`, category = module name without the
  `Snapbolt` prefix (`"Upload"`, `"Capture"`).
- Each module has one `Logger` declared in `Logging.swift`:
  `let logger = Logger(subsystem: "io.github.siracozmen01.Snapbolt", category: "Upload")`.
- Levels: `debug` for development tracing, `info` for lifecycle events, `error` for failures that
  reach the user, `fault` for broken invariants.
- **Privacy:** secrets (Secret Access Key, signatures, `Authorization` headers) are never logged.
  URLs, object keys, file paths and window titles use `privacy: .private`.
- `print` and `NSLog` are not used.
