# Concurrency

All targets build in **Swift 6 language mode** with complete strict concurrency checking. Data-race
warnings are errors.

## Rules

1. **UI is `@MainActor`.** Views, panels, controllers, menu bar code and `@Observable` view models
   are annotated `@MainActor`.
2. **Domain values are `Sendable` value types.** Types in `SnapboltCore` are structs or enums
   conforming to `Sendable`. `CGImage` is wrapped where needed; do not pass `NSImage` across actors.
3. **Long work is `async` and off the main actor.** Capture, PNG encoding, file writes and network
   calls are `async` functions on non-main-actor types (`nonisolated`, actors, or `Sendable`
   structs).
4. **Shared mutable state lives in an actor.** For example, the history store is an `actor`.
5. **Structured concurrency first.** Prefer `async let` and `withThrowingTaskGroup` over unstructured
   `Task { }`. An unstructured `Task` is acceptable at an entry point (shortcut handler, button
   action) and must be owned or documented.
6. **No GCD in new code.** No `DispatchQueue`, `DispatchGroup` or semaphores, except to bridge an API
   that offers nothing else; wrap it in `withCheckedThrowingContinuation` and keep it in one place.
7. **Continuations are resumed exactly once.** Use `withCheckedContinuation` (not the unsafe variant).
8. **Cancellation is respected.** Long loops and retries call `try Task.checkCancellation()`.
9. **`@unchecked Sendable` and `nonisolated(unsafe)` need a comment** explaining why the type is
   actually safe, and a reviewer's agreement.
10. **`@preconcurrency import`** only for Apple frameworks not yet annotated, with a comment.

## Typical shapes

```swift
// Feature implementation: stateless and Sendable, safe to call from anywhere.
public struct ScreenCaptureKitCapturer: ScreenCapturing {
    public func freezeAllDisplays() async throws -> FrozenScreens { … }
}

// Shared mutable state: an actor.
public actor HistoryStore: UploadHistoryStoring {
    private var entries: [HistoryEntry] = []
    public func add(_ entry: HistoryEntry) async throws { … }
}

// UI: main actor.
@MainActor
final class OverlayController {
    func select(on screens: FrozenScreens) async -> Selection? { … }
}
```
