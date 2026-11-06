import AppKit
import SnapboltCore

/// The in-place text view the text tool opens. It reports its text once, when it closes.
///
/// It owns a plain `NSTextView` instead of subclassing one: AppKit's initializers call
/// `init(frame:textContainer:)` on the subclass, which a subclass with its own initializer cannot provide.
@MainActor
final class TextEditingField: NSObject, NSTextViewDelegate {
    /// The view to add to the canvas and make first responder.
    let textView: NSTextView
    private var text: TextAnnotation
    private let mapping: CanvasMapping
    private let onCommit: @MainActor (String) -> Void
    private var isCommitted = false

    init(text: TextAnnotation, mapping: CanvasMapping, onCommit: @escaping @MainActor (String) -> Void) {
        self.text = text
        self.mapping = mapping
        self.onCommit = onCommit
        textView = NSTextView(frame: Self.frame(for: text, mapping: mapping))
        super.init()
        configure()
        textView.delegate = self
    }

    /// The text typed so far.
    var string: String { textView.string }

    /// The field's frame on the canvas: exactly the text shape's bounds.
    static func frame(for text: TextAnnotation, mapping: CanvasMapping) -> CGRect {
        mapping.canvasRect(fromPixels: text.boundsInPixels)
    }

    /// Closes the field and reports its text; later calls do nothing.
    func commit() {
        guard !isCommitted else { return }
        isCommitted = true
        onCommit(string)
    }

    // MARK: - NSTextViewDelegate

    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        // Escape commits the text instead of reaching the canvas, where it would cancel the editor.
        guard commandSelector == #selector(NSResponder.cancelOperation(_:)) else { return false }
        commit()
        return true
    }

    func textDidChange(_ notification: Notification) {
        text.string = string
        textView.frame = Self.frame(for: text, mapping: mapping)
    }

    func textDidEndEditing(_ notification: Notification) {
        commit()
    }

    private func configure() {
        let color = NSColor(cgColor: text.color.cgColor) ?? .systemRed
        textView.font = NSFont.systemFont(ofSize: mapping.points(fromPixels: text.fontSizeInPixels))
        textView.textColor = color
        textView.insertionPointColor = color
        textView.string = text.string
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        let padding = mapping.points(fromPixels: text.paddingInPixels)
        textView.textContainerInset = NSSize(width: padding, height: padding)
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
    }
}
