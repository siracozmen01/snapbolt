// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation
// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import SnapboltCore

/// Returns a stored selection, or suspends until resume(with:) when suspends is set.
@MainActor
public final class FakeSelectionPresenter: SelectionPresenting {
    public var result: Selection?
    public var suspends = false
    public private(set) var presentationCount = 0
    private var pending: CheckedContinuation<Selection?, Never>?

    public init(result: Selection? = nil) {
        self.result = result
    }

    public func select(on screens: FrozenScreens) async -> Selection? {
        presentationCount += 1
        guard suspends else { return result }
        return await withCheckedContinuation { pending = $0 }
    }

    public func resume(with selection: Selection?) {
        pending?.resume(returning: selection)
        pending = nil
    }
}
