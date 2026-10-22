import AppKit
import SnapboltCore

/// The in-place text view the text tool opens. It reports its text once, when it closes.
@MainActor
final class TextEditingField: NSTextView {
    private var text: TextAnnotation
    private let mapping: CanvasMapping
    private let onCommit: @MainActor (String) -> Void
    private var isCommitted = false

    init(text: TextAnnotation, mapping: CanvasMapping, onCommit: @escaping @MainActor (String) -> Void) {
        self.text = text
        self.mapping = mapping
        self.onCommit = onCommit
        super.init(frame: Self.frame(for: text, mapping: mapping))
        configure()
    }

    @available(*, unavailable, message: "Created in code only")
    required init?(coder: NSCoder) {
        preconditionFailure("TextEditingField is never loaded from a nib")
    }

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

    override func cancelOperation(_ sender: Any?) {
        commit()
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned { commit() }
        return resigned
    }

    override func didChangeText() {
        super.didChangeText()
        text.string = string
        frame = Self.frame(for: text, mapping: mapping)
    }

    private func configure() {
        let color = NSColor(cgColor: text.color.cgColor) ?? .systemRed
        font = NSFont.systemFont(ofSize: mapping.points(fromPixels: text.fontSizeInPixels))
        textColor = color
        insertionPointColor = color
        string = text.string
        isRichText = false
        allowsUndo = true
        drawsBackground = false
        let padding = mapping.points(fromPixels: text.paddingInPixels)
        textContainerInset = NSSize(width: padding, height: padding)
        textContainer?.lineFragmentPadding = 0
        textContainer?.widthTracksTextView = false
        textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        isHorizontallyResizable = true
        isVerticallyResizable = true
    }
}
