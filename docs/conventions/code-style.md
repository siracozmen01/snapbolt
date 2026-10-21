# Code style

Formatting is not discussed in review: `swift format` decides it (`make format`), and CI fails on
any difference (`swift format lint --strict`). SwiftLint checks the rules below that a formatter
cannot (`make lint`, `swiftlint --strict` in CI).

Base rules: the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
This document lists where we are stricter or where a choice had to be made.

## Formatting (enforced by swift-format)

- 4 spaces, no tabs. LF line endings, one trailing newline.
- Maximum line length **120** characters.
- Trailing commas in multi-line collection literals and argument lists.
- One blank line between declarations; no multiple blank lines.
- Opening braces on the same line.

## Language features

- **No force unwrap (`!`), force try (`try!`) or force cast (`as!`)** in production code.
  Tests may use them when a failure should crash the test. If a value truly cannot be nil, use
  `guard let … else { preconditionFailure("why this is impossible") }`.
- **No implicitly unwrapped optionals**, except `@IBOutlet` (which we do not use).
- **Prefer `let` over `var`**, value types over classes. Use a class only for identity or reference
  semantics (AppKit subclasses, observable models, objects with lifetimes).
- **Mark classes `final`** unless designed for subclassing.
- **`guard` for early exit**; keep the happy path at the lowest indentation.
- **No global mutable state and no singletons of our own.** System singletons (`NSPasteboard.general`,
  `UserDefaults.standard`, `FileManager.default`) are used only inside `SnapboltSystem` /
  `SnapboltSettings` adapters and injected elsewhere.
- **Dependency injection through initializers.** No service locators, no property injection.
- **No `print`.** Use `os.Logger` (see [error-handling.md](error-handling.md#logging)).
- **No magic numbers** in logic: name them (`static let maxRetries = 2`). Layout constants in views
  may be literal when local and obvious.
- **Avoid stringly-typed code.** Use enums for fixed sets (`CaptureMode`), types for identifiers
  (`struct DisplayID: Hashable, Sendable { let rawValue: CGDirectDisplayID }`).
- **Closures:** use trailing closure syntax for the last closure only. Prefer `[weak self]` in
  escaping closures stored by long-lived objects; do not add it reflexively to non-escaping ones.
- **Extensions** group protocol conformances: `extension Uploader: Equatable { … }`, one per
  conformance.

## Access control

- Default to the most restrictive level that compiles: `private` > `fileprivate` > `internal` >
  `public`.
- `public` only for API another module uses. Every `public` declaration has a doc comment.
- No `open`: nothing is designed for subclassing across modules.
- `@testable import` is allowed in tests only.

## AppKit vs SwiftUI

| Use | For |
|---|---|
| AppKit | Overlay panels and views, menu bar status item, anything needing window levels, collection behaviour or event handling below SwiftUI |
| SwiftUI | Settings, onboarding, history list — forms and standard controls |

- SwiftUI views are small: a `body` longer than ~30 lines is split into subviews.
- Views contain no business logic. They read from an `@Observable` model and call its methods.
- Use the Observation framework (`@Observable`), not `ObservableObject`/`@Published`, in new code.

## Platform availability

The deployment target is macOS 15.0 ([ADR 0005](../adr/0005-macos-15-minimum.md)). Newer APIs are
used only behind `if #available(macOS 15.2, *)` with a working fallback.
