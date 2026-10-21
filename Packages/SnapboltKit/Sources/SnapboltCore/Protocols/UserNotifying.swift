import Foundation

/// Tells the user how a capture ended.
public protocol UserNotifying: Sendable {
    /// Announces that the link to an upload is on the clipboard.
    func notifyLinkCopied(_ url: URL) async
    /// Shows `error`, offering its recovery action.
    func notify(_ error: UserFacingError) async
}
