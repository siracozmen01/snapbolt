// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation

// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import Foundation
import SnapboltCore

/// Records notifications.
public actor SpyNotifier: UserNotifying {
    public private(set) var linksCopied: [URL] = []
    public private(set) var errors: [UserFacingError] = []

    public init() {}

    public func notifyLinkCopied(_ url: URL) async {
        linksCopied.append(url)
    }

    public func notify(_ error: UserFacingError) async {
        errors.append(error)
    }
}
