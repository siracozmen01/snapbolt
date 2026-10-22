import CoreGraphics

/// The editor window's first size and zoom.
struct EditorWindowLayout: Equatable {
    static let toolbarHeight: CGFloat = 52
    /// The window is never narrower than this, so the toolbar fits.
    static let minimumContentWidth: CGFloat = 760
    /// The window takes at most this share of the screen's visible frame.
    static let maximumScreenShare: CGFloat = 0.85

    /// The window's content size: the toolbar plus the canvas area.
    let contentSize: CGSize
    let magnification: CGFloat

    /// 100% when the image fits in 85% of the screen, otherwise fitted to that size.
    static func initial(imageSizeInPoints: CGSize, visibleFrame: CGRect) -> EditorWindowLayout {
        let maximum = CGSize(
            width: visibleFrame.width * maximumScreenShare, height: visibleFrame.height * maximumScreenShare)
        let fits =
            imageSizeInPoints.width <= maximum.width
            && imageSizeInPoints.height + toolbarHeight <= maximum.height
        guard fits else {
            let canvas = CGSize(width: maximum.width, height: maximum.height - toolbarHeight)
            return EditorWindowLayout(
                contentSize: maximum, magnification: ZoomLevels.fitting(imageSizeInPoints, in: canvas))
        }
        let width = min(max(imageSizeInPoints.width, minimumContentWidth), maximum.width)
        return EditorWindowLayout(
            contentSize: CGSize(width: width, height: imageSizeInPoints.height + toolbarHeight), magnification: 1)
    }
}
