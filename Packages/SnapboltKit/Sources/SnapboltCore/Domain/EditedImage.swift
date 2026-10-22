import CoreGraphics

/// The result of editing a capture.
public struct EditedImage: Sendable {
    /// Where the edited image goes next.
    public enum Destination: Equatable, Sendable {
        /// Save, upload and copy the link, as for an unedited capture.
        case upload
        /// Save and copy the image itself, without uploading.
        case clipboard
    }

    /// The edited pixels, already cropped.
    public let image: CGImage
    /// Where the image goes next.
    public let destination: Destination

    /// Creates an edited image.
    public init(image: CGImage, destination: Destination) {
        self.image = image
        self.destination = destination
    }
}
