# Testing

## Framework and layout

- [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`) for all new
  tests. XCTest only where Swift Testing cannot do the job (none known in Phase 1).
- One test target per module: `Tests/SnapboltUploadTests/` tests `SnapboltUpload`.
- Test files mirror source files: `SigV4Signer.swift` → `SigV4SignerTests.swift`.
- Shared fakes live in a `SnapboltTestSupport` target that only test targets depend on.

## What must be tested

| Code | Expectation |
|---|---|
| Pure logic (geometry, signing, key templates, error mapping) | Unit tested, including edge cases |
| `SnapboltWorkflow` | Every path tested with fakes: success, upload failure, not configured, cancelled, permission denied |
| Network code | Request building and response/error parsing tested with a `URLProtocol` stub; no real network |
| AppKit / SwiftUI views | Logic extracted into models and tested there; visual behaviour covered by [manual tests](../testing.md) |
| ScreenCaptureKit, Keychain, notifications | Thin adapters, covered by the manual checklist |

A bug fix comes with a test that fails without the fix.

## Writing tests

```swift
import Testing
@testable import SnapboltUpload

@Suite("Object key template")
struct ObjectKeyTemplateTests {

    @Test("Expands date tokens using the given date")
    func expandsDateTokens() throws {
        let template = ObjectKeyTemplate("{yyyy}/{MM}/{dd}")
        let key = template.expand(date: .fixture(2026, 10, 21), random: "abc")
        #expect(key == "2026/10/21")
    }

    @Test("Rejects templates without a random token", arguments: ["{yyyy}", "static-name"])
    func rejectsTemplatesWithoutRandom(_ raw: String) {
        #expect(throws: ObjectKeyTemplate.Error.missingRandomToken) {
            try ObjectKeyTemplate(validating: raw)
        }
    }
}
```

- **Names describe behaviour**, not methods: `expandsDateTokens`, not `testExpand`.
- **Arrange / act / assert**, separated by a blank line when the test is longer than a few lines.
- **One behaviour per test.** Several `#expect`s are fine if they check one behaviour.
- **Parameterized tests** (`arguments:`) instead of copy-pasted tests.
- **`#require`** to unwrap and stop early; `#expect` for assertions.
- **Deterministic:** inject clocks, random sources and dates. No `sleep`, no real time, no reliance
  on test order.
- **No real network, disk outside a temporary directory, Keychain or permissions** in unit tests.

## Test doubles

- Hand-written, no mocking frameworks.
- `Fake…` — a working lightweight implementation (in-memory history store).
- `Stub…` — returns canned values.
- `Spy…` — records calls for assertions (`SpyClipboard.writtenURLs`).

## Integration tests

`SnapboltUploadIntegrationTests` run against a real bucket only when these environment variables
are set, and are skipped otherwise (`.enabled(if:)`):

`SNAPBOLT_IT_ENDPOINT`, `SNAPBOLT_IT_REGION`, `SNAPBOLT_IT_BUCKET`, `SNAPBOLT_IT_ACCESS_KEY_ID`,
`SNAPBOLT_IT_SECRET_ACCESS_KEY`, `SNAPBOLT_IT_PUBLIC_BASE_URL`.

They are not run in CI.

## Running

```bash
make test          # all package tests
make test FILTER=SnapboltUploadTests
```
