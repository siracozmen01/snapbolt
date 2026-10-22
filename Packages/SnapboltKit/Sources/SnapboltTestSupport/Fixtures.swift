// swift-format-ignore-file: AllPublicDeclarationsHaveDocumentation

// Test doubles are documented by their type comment; per-member docs would only repeat the protocol.
import CoreGraphics
import Foundation
import SnapboltCore

extension StorageSettings {
    /// R2-style settings with fixed values for tests.
    public static func fixture(
        endpoint: String = "https://acc.r2.cloudflarestorage.com",
        bucket: String = "shots",
        publicBaseURL: String = "https://i.example.com"
    ) -> StorageSettings {
        guard let endpointURL = URL(string: endpoint), let baseURL = URL(string: publicBaseURL) else {
            preconditionFailure("Fixture URLs must be valid")
        }
        return StorageSettings(
            endpoint: endpointURL, region: "auto", bucket: bucket, accessKeyID: "KEY",
            secretAccessKey: "SECRET", publicBaseURL: baseURL, keyTemplate: .defaultTemplate)
    }
}

extension FrozenDisplay {
    /// A display at the global origin with a solid image of the given pixel size.
    public static func fixture(id: UInt32 = 1, width: Int = 100, height: Int = 100, scale: CGFloat = 1)
        -> FrozenDisplay
    {
        FrozenDisplay(
            id: DisplayID(rawValue: id), image: .solid(width: width, height: height),
            frameInGlobalPoints: CGRect(x: 0, y: 0, width: CGFloat(width) / scale, height: CGFloat(height) / scale),
            scale: scale)
    }
}
