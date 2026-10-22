# Snapbolt Phase 2 (Annotation Editor) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task, inline in one session. This project does not use subagents. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An optional editor between capture and upload. When **Edit After Capture** is on, every capture opens in a window with arrow, rectangle, text, redaction and crop tools, and the user uploads, copies or cancels the result.

**Architecture:** A new feature module `SnapboltEditor` (depends only on `SnapboltCore`) implements a new Core protocol `ImageEditing`. `SnapboltWorkflow` calls it between crop and encode. Inside the module, a value-type `AnnotationDocument` is changed by pure tool types and drawn by one Core Graphics renderer that serves both the AppKit canvas and the exporter.

**Tech Stack:** Swift 6 (language mode 6), macOS 15+, AppKit (canvas, window), SwiftUI (toolbar), Core Graphics, Core Text, Core Image, Swift Testing. No new third-party dependencies.

**Spec:** [docs/specs/2026-10-22-snapbolt-phase-2-editor-design.md](../specs/2026-10-22-snapbolt-phase-2-editor-design.md). Read it, [docs/architecture.md](../architecture.md) and [AGENTS.md](../../AGENTS.md) before starting any task. Paths below are relative to `Packages/SnapboltKit/` unless they start with `App/` or `docs/`.

## Prerequisites

- Xcode 26 or newer selected; `make bootstrap` done.
- Work on branch `feat/phase-2-editor` from `main`; never commit to `main` directly.

## Global Constraints

- Module rules: `SnapboltEditor` imports only `SnapboltCore`, AppKit, SwiftUI, CoreGraphics, CoreImage, CoreText, Observation, Foundation, os. Only `App/AppEnvironment.swift` constructs `EditorController`.
- All coordinate conversions live in `Sources/SnapboltCore/Geometry/`. Identifiers name their space: `…InPixels` (image pixels, top-left origin, y down), `…InPoints` (style sizes at 100% zoom), canvas points are the flipped canvas view's coordinates.
- All editor drawing assumes a **y-down** context whose user space is image pixels; CGImages are drawn through `AnnotationRenderer.drawImage`, which flips locally.
- Preferences: `capture.opensEditor` (Bool, default `false`); per-tool style `editor.style.<tool rawValue>` (JSON-encoded `ToolStyle`).
- Style ranges and defaults: line width 1–40 pt (default 4), font size 8–200 pt (default 24), redaction strength 1–100 (default 40), colour default `#FF3B30` opaque, rectangle outline, text without background, redaction mode Pixelate. Shapes store `points × capture scale`.
- Redaction: pixelate block `(4 + 28 × strength / 100) pt × scale`; blur radius `(2 + 23 × strength / 100) pt × scale`; patches always sample the original image.
- Arrow head length `max(lineWidth × 4, 10 px)`, head width equal to its length; the shaft ends at the head's base.
- Text background: rounded box, padding `fontSize × 0.25`, black at 60% for light text, white at 80% for dark text (relative luminance > 0.5 = light).
- Minimum shape drag 3 pt in both directions; hit tolerance 6 screen points; handles 8 screen points; nudge 1 px, 10 px with ⇧; undo limit 100; zoom 10%–800%; nearest-neighbour interpolation above 200%.
- Initial tool `.arrow`. Tool keys V A R T B C. ⌘Z / ⇧⌘Z, ⌘+ / ⌘− / ⌘0 / ⌘1, ⌘Return Upload, ⇧⌘C Copy, Escape commits text or cancels. All keys are handled in one place: `EditorCanvasView+Keyboard.swift`.
- Exact UI copy: menu item `Edit After Capture`; settings section `Editor`, toggle `Open the editor after each capture`; window title `Snapbolt Editor`; buttons `Cancel`, `Copy`, `Upload`; sheet `Discard this capture?` with `Discard` / `Keep Editing`; alert `Could not export the edited image.`; redaction help `Use Pixelate for sensitive data; weak blur can sometimes be reversed.` All through `String(localized:)`.
- Export never falls back to the unedited image.
- File ≤ 300 lines, type ≤ 200, function ≤ 40, complexity ≤ 12 (warnings at 250/150/30/8 fail CI too). One primary type per file. No `!`, `try!`, `as!`, `print`, GCD, singletons; `try?`/empty `catch` only with a justification comment. `///` on every `public` declaration.
- Commits: Conventional Commits, scope = module (`feat(editor): …`), ending with the `Co-Authored-By` trailer.
- Every task ends with `make test` and `make lint` green.

## Review Focus

1. **Retina captures:** a 4 pt arrow on a scale-2 capture must export as an 8 px stroke, and what the canvas shows must match the export. → `exportsStylesInPixelsAtScaleTwo` in Task 8.
2. **Flipped coordinates:** the exported image must not be upside down, and a redaction over the top of the image must sample the top (Core Image is y-up). → `exportKeepsOrientation` in Task 8, `samplesTheAreaUnderTheRedaction` in Task 7.
3. **One gesture = one undo step:** dragging a shape through 50 mouse events, editing a text or restyling must each undo in one ⌘Z. → `dragIsOneUndoStep`, `textEditIsOneUndoStep` in Task 9.
4. **Double finish:** pressing Upload twice, or Cancel during export, must finish the edit exactly once. → `finishesOnlyOnce` in Task 9.
5. **Two editors at once:** a second capture while an editor is open must open its own editor, and both captures must finish independently. → `twoEditorsFinishIndependently` in Task 12.

---

## File Structure

```
Sources/SnapboltCore/
  Domain/CapturedImage.swift, Domain/EditedImage.swift            new
  Domain/CapturePreferences.swift, Domain/Selection.swift          modified
  Protocols/ImageEditing.swift                                     new
  Geometry/CanvasMapping.swift                                     new
  Geometry/CoordinateConversion.swift, Geometry/ImageCropper.swift modified
Sources/SnapboltEditor/
  EditorController.swift, Logging.swift
  Document/   AnnotationDocument, Annotation, AnnotationShape, Annotation+Shape,
              ArrowAnnotation, RectangleAnnotation, TextAnnotation, RedactionAnnotation
  Editing/    EditorState, EditorTool, ToolStyle, ToolStylePreferences, Handle,
              RectResizing, AnnotationHitTester, EditHistory
  Tools/      ToolInteraction, PointerInput, SelectionTool, ShapeDrawingTool, TextTool, CropTool
  Rendering/  RGBAColor, RedactionMode, TextLayout, RedactionRenderer, AnnotationRenderer,
              DocumentExporting, ImageExporter, EditorError
  Canvas/     EditorCanvasView, +Mouse, +Keyboard, +Drawing, TextEditingField, ZoomLevels
  Toolbar/    EditorToolbarView, ToolPickerView, StyleControlsView
  Window/     EditorWindowController, EditorWindowLayout, EditorModel, EditorModel+Actions,
              EditorModel+Finishing
Sources/SnapboltWorkflow/  CaptureWorkflow.swift, CaptureWorkflow+Dependencies.swift (modified),
                           CaptureWorkflow+Editing.swift (new)
Sources/SnapboltSettings/  SettingsStore, General/GeneralSettingsModel, General/GeneralSettingsView (modified)
Sources/SnapboltTestSupport/ FakeImageEditor, PixelColor, CGImage+Pixels (new); Fixtures (modified)
Tests/SnapboltEditorTests/  mirror the source files; Support/TestPatterns.swift
App/  AppEnvironment.swift, AppDelegate.swift, Windows/SettingsWindowController.swift,
      MenuBar/MenuBarController.swift (modified); MenuBar/ToggleMenuItem.swift (new)
```

This refines spec §4.6: `EditHistory` sits in `Editing/` and `RGBAColor` in `Rendering/` to keep each folder at eight files or fewer; the redaction cache is private to `RedactionRenderer`; `RedactionMode`, `RectResizing`, `PointerInput`, `DocumentExporting`, `EditorError`, `ZoomLevels` and `EditorWindowLayout` are added.

---

### Task 1: Core contract

**Files:**
- Create: `Sources/SnapboltCore/Domain/CapturedImage.swift`, `Domain/EditedImage.swift`, `Protocols/ImageEditing.swift`, `Geometry/CanvasMapping.swift`
- Modify: `Domain/CapturePreferences.swift`, `Domain/Selection.swift`, `Geometry/CoordinateConversion.swift`, `Geometry/ImageCropper.swift`
- Create: `Sources/SnapboltTestSupport/FakeImageEditor.swift`, `PixelColor.swift`, `CGImage+Pixels.swift`; modify `Fixtures.swift`
- Test: `Tests/SnapboltCoreTests/CanvasMappingTests.swift`, `SelectionTests.swift`, `CapturePreferencesTests.swift`, `CoordinateConversionTests.swift`

**Interfaces:**
- Produces:

```swift
public struct CapturedImage: Sendable { public let image: CGImage; public let scale: CGFloat; public init(image:scale:) }
public struct EditedImage: Sendable {
    public enum Destination: Equatable, Sendable { case upload, clipboard }
    public let image: CGImage; public let destination: Destination; public init(image:destination:)
}
@MainActor public protocol ImageEditing { func edit(_ capture: CapturedImage) async -> EditedImage? }
// CapturePreferences: public let opensEditor: Bool; init(saveLocally:folder:opensEditor: Bool = false)
extension Selection { public var displayID: DisplayID { get } }
public struct CanvasMapping: Equatable, Sendable {
    public let scale: CGFloat            // pixels per point
    public var magnification: CGFloat    // scroll view magnification, 1 = 100%
    public init(scale: CGFloat, magnification: CGFloat = 1)
    public func canvasPoint(fromPixel point: CGPoint) -> CGPoint
    public func pixelPoint(fromCanvas point: CGPoint) -> CGPoint
    public func canvasRect(fromPixels rect: CGRect) -> CGRect
    public func pixelRect(fromCanvas rect: CGRect) -> CGRect
    public func pixels(fromPoints length: CGFloat) -> CGFloat        // style sizes: × scale
    public func points(fromPixels length: CGFloat) -> CGFloat
    public func pixels(fromScreenPoints length: CGFloat) -> CGFloat  // ÷ magnification × scale
}
// CoordinateConversion:
public static func bottomUpRect(fromTopDownRect rect: CGRect, imageHeight: CGFloat) -> CGRect  // its own inverse
// TestSupport:
@MainActor public final class FakeImageEditor: ImageEditing {
    public var result: EditedImage?; public var suspends: Bool
    public private(set) var receivedCaptures: [CapturedImage]
    public func resumeNext(with result: EditedImage?)   // resumes the oldest suspended edit
}
public struct PixelColor: Equatable, Sendable { public let red, green, blue, alpha: UInt8 }
extension CGImage { public func pixel(atX x: Int, y: Int) -> PixelColor }  // y = 0 is the top row
// FrozenDisplay.fixture gains `scale: CGFloat = 1`; the frame is width/scale × height/scale points
```

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `CanvasMappingTests.roundTripsPoints` (arguments: scale 1, 2; magnification 0.5, 1, 3) | `pixelPoint(fromCanvas: canvasPoint(fromPixel: (37, 81))) == (37, 81)` |
  | `CanvasMappingTests.canvasIsPixelsOverScale` | scale 2: `canvasRect(fromPixels: (10, 20, 100, 50)) == (5, 10, 50, 25)` |
  | `CanvasMappingTests.screenToleranceShrinksWithZoom` | scale 2, magnification 4: `pixels(fromScreenPoints: 6) == 3` |
  | `CanvasMappingTests.styleSizesScale` | scale 2: `pixels(fromPoints: 4) == 8`, `points(fromPixels: 8) == 4` |
  | `SelectionTests.exposesDisplayID` (each case) | `.region(d, …)`, `.window(d, …)`, `.display(d)` all give `d` |
  | `CoordinateConversionTests.flipsRectBetweenTopDownAndBottomUp` | height 100: `(10, 20, 30, 40)` ↔ `(10, 40, 30, 40)`; applying twice returns the input |
  | `CapturePreferencesTests.editorIsOffByDefault` | `CapturePreferences(saveLocally: true, folder: f).opensEditor == false` |

- [ ] **Step 2: Run** `make test FILTER=SnapboltCoreTests` → FAIL (`cannot find 'CanvasMapping' in scope`).
- [ ] **Step 3: Implement** the Core types; `ImageCropper` uses `selection.displayID` instead of its private helper's display half. Add the TestSupport types; `pixel(atX:y:)` draws the image into a 1×1 RGBA premultiplied-last context offset so the requested pixel lands on it.
- [ ] **Step 4: Run** `make test` → PASS (all existing tests untouched). `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(core): add image editing contract and canvas mapping`

---

### Task 2: Editor module and style values

**Files:**
- Modify: `Package.swift` (add `"SnapboltEditor"` to `featureModules` and `testedModules`)
- Create: `Sources/SnapboltEditor/Logging.swift` (category `"Editor"`), `Rendering/RGBAColor.swift`, `Rendering/RedactionMode.swift`, `Editing/ToolStyle.swift`, `Editing/EditorTool.swift`, `Editing/Handle.swift`, `Editing/RectResizing.swift`
- Test: `Tests/SnapboltEditorTests/RGBAColorTests.swift`, `ToolStyleTests.swift`, `EditorToolTests.swift`, `RectResizingTests.swift`

**Interfaces:**
- Produces:

```swift
struct RGBAColor: Codable, Hashable, Sendable {
    var red, green, blue, alpha: Double                // sRGB, 0…1
    static let defaultRed: RGBAColor                   // #FF3B30, alpha 1
    init(red:green:blue:alpha:); init?(cgColor: CGColor)  // converts to sRGB
    var cgColor: CGColor; var relativeLuminance: Double   // WCAG formula
    var isLight: Bool                                  // relativeLuminance > 0.5
}
enum EditorTool: String, CaseIterable, Codable, Sendable {
    case select, arrow, rectangle, text, redaction, crop
    var shortcutKey: Character                          // v a r t b c
    init?(shortcutKey: Character)
}
struct ToolStyle: Codable, Equatable, Sendable {
    static let lineWidthRangeInPoints: ClosedRange<CGFloat> = 1...40
    static let fontSizeRangeInPoints: ClosedRange<CGFloat> = 8...200
    static let strengthRange: ClosedRange<Double> = 1...100
    static let standard: ToolStyle                       // defaults from Global Constraints
    var color: RGBAColor; var lineWidthInPoints: CGFloat; var isFilled: Bool
    var fontSizeInPoints: CGFloat; var hasBackground: Bool
    var redactionMode: RedactionMode; var redactionStrength: Double
    func clamped() -> ToolStyle
}
enum RedactionMode: String, Codable, Sendable { case pixelate, blur }    // Rendering/RedactionMode.swift
enum Handle: CaseIterable, Hashable, Sendable {
    case start, end, topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left
    static let rectHandles: [Handle]                     // the eight rect handles
    static func positions(for rect: CGRect) -> [Handle: CGPoint]
}
enum RectResizing {
    static func resized(_ rect: CGRect, dragging handle: Handle, to point: CGPoint) -> CGRect   // standardized
    static func rect(from start: CGPoint, to end: CGPoint, square: Bool) -> CGRect
}
```

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `RGBAColorTests.roundTripsThroughCGColor` | `RGBAColor(cgColor: c.cgColor) == c` for `defaultRed` and a 50%-alpha blue |
  | `RGBAColorTests.classifiesLightness` | white and yellow are light; black and `defaultRed` are not |
  | `ToolStyleTests.standardMatchesSpec` | colour `defaultRed`, width 4, font 24, outline, no background, pixelate, strength 40 |
  | `ToolStyleTests.clampsToRanges` | width 0 → 1, 99 → 40; font 2 → 8, 500 → 200; strength 0 → 1, 150 → 100 |
  | `ToolStyleTests.roundTripsThroughJSON` | encode + decode is equal |
  | `EditorToolTests.mapsShortcutKeys` (arguments: all cases) | `EditorTool(shortcutKey: tool.shortcutKey) == tool`; `EditorTool(shortcutKey: "x") == nil` |
  | `RectResizingTests.dragsEachHandle` (arguments: 8 handles) | rect `(10, 10, 100, 50)`, drag handle to `(0, 0)` → expected rect per handle (e.g. `.topLeft` → `(0, 0, 110, 60)`, `.right` → `(0, 10, 10, 50)`) |
  | `RectResizingTests.flipsWhenDraggedPastOppositeEdge` | `.right` dragged to `x = 0` from rect at `x = 10` gives a standardized rect with positive width |
  | `RectResizingTests.squaresWithShift` | `rect(from: (0,0), to: (30, -10), square: true) == (0, -30, 30, 30)` |

- [ ] **Step 2: Run** `make test FILTER=SnapboltEditorTests` → FAIL.
- [ ] **Step 3: Implement** the types above.
- [ ] **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add editor module with tools, styles and handles`

---

### Task 3: Annotation shapes and document

**Files:**
- Create: `Sources/SnapboltEditor/Document/AnnotationShape.swift`, `ArrowAnnotation.swift`, `RectangleAnnotation.swift`, `TextAnnotation.swift`, `RedactionAnnotation.swift`, `Annotation.swift`, `Annotation+Shape.swift`, `AnnotationDocument.swift`, `Rendering/TextLayout.swift`
- Test: `Tests/SnapboltEditorTests/ArrowAnnotationTests.swift`, `RectangleAnnotationTests.swift`, `TextAnnotationTests.swift`, `RedactionAnnotationTests.swift`, `AnnotationDocumentTests.swift`

**Interfaces:**
- Consumes: Task 2 types.
- Produces:

```swift
protocol AnnotationShape: Equatable, Sendable {
    var boundsInPixels: CGRect { get }
    var handlePositions: [Handle: CGPoint] { get }
    func contains(_ pointInPixels: CGPoint, toleranceInPixels: CGFloat) -> Bool
    func moved(by offset: CGVector) -> Self
    func resized(dragging handle: Handle, to pointInPixels: CGPoint) -> Self
    func restyled(_ style: ToolStyle, scale: CGFloat) -> Self          // points → pixels
    func style(applyingTo base: ToolStyle, scale: CGFloat) -> ToolStyle // pixels → points
}
struct ArrowAnnotation: AnnotationShape { var startInPixels, endInPixels: CGPoint; var color: RGBAColor; var lineWidthInPixels: CGFloat
    var headLengthInPixels: CGFloat; var shaftEndInPixels: CGPoint; var headPointsInPixels: [CGPoint] /* tip, left, right */ }
struct RectangleAnnotation: AnnotationShape { var rectInPixels: CGRect; var color: RGBAColor; var lineWidthInPixels: CGFloat; var isFilled: Bool }
struct TextAnnotation: AnnotationShape { var string: String; var originInPixels: CGPoint; var color: RGBAColor
    var fontSizeInPixels: CGFloat; var hasBackground: Bool; var paddingInPixels: CGFloat /* hasBackground ? fontSize × 0.25 : 0 */ }
struct RedactionAnnotation: AnnotationShape, Hashable { var rectInPixels: CGRect; var mode: RedactionMode; var strength: Double }
struct TextLayout { init(string: String, fontSizeInPixels: CGFloat); var sizeInPixels: CGSize
    func draw(in context: CGContext, at originInPixels: CGPoint, color: RGBAColor) }  // y-down context
struct Annotation: Identifiable, Equatable, Sendable {
    let id: UUID; var kind: Kind
    enum Kind: Equatable, Sendable { case arrow(ArrowAnnotation), rectangle(RectangleAnnotation), text(TextAnnotation), redaction(RedactionAnnotation) }
}
extension Annotation {   // Annotation+Shape.swift: forwards every AnnotationShape member to the payload
    var boundsInPixels: CGRect; var handlePositions: [Handle: CGPoint]; var tool: EditorTool
    func contains(_:toleranceInPixels:) -> Bool; func moved(by:) -> Annotation; func resized(dragging:to:) -> Annotation
    func restyled(_:scale:) -> Annotation; func style(applyingTo:scale:) -> ToolStyle
}
struct AnnotationDocument: Equatable, Sendable {
    let imageSizeInPixels: CGSize; var annotations: [Annotation]; var cropRectInPixels: CGRect?
    init(imageSizeInPixels: CGSize)
    var imageBoundsInPixels: CGRect; var exportRectInPixels: CGRect   // crop ?? image bounds
    func annotation(withID id: Annotation.ID) -> Annotation?
    mutating func upsert(_ annotation: Annotation)    // replaces in place or appends on top
    mutating func remove(id: Annotation.ID)
}
```

Shape rules: arrow hit = distance to the segment ≤ `tolerance + lineWidth / 2`, handles `.start`/`.end`; rectangle outline hit = within `tolerance + lineWidth / 2` of an edge, filled hit = inside the rect grown by tolerance; redaction hit = inside the rect grown by tolerance; rect and redaction handles = `Handle.rectHandles`, resize via `RectResizing`; text bounds = `TextLayout` size plus padding on all sides at `originInPixels`, hit = inside bounds grown by tolerance, handles = four corners, resizing scales `fontSizeInPixels` by new height / old height with the opposite corner fixed, minimum 4 px.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `ArrowAnnotationTests.headSizeFollowsLineWidth` | width 2 → head 10; width 8 → head 32; shaft ends 32 px before the tip |
  | `ArrowAnnotationTests.hitsNearTheShaft` | arrow (0,0)→(100,0), width 4, tolerance 6: (50, 7) hits, (50, 9) misses, (120, 0) misses |
  | `ArrowAnnotationTests.dragsEndpoints` | `.end` to (10, 90) moves only the end |
  | `RectangleAnnotationTests.outlineHitsOnlyNearEdges` | outline rect (0,0,100,100): (50, 2) hits, (50, 50) misses; filled: (50, 50) hits |
  | `RectangleAnnotationTests.restylesInPixels` | `restyled(style with width 4 pt, scale: 2).lineWidthInPixels == 8`; `style(applyingTo:scale: 2).lineWidthInPoints == 4` |
  | `TextAnnotationTests.boundsIncludePadding` | font 40 px with background: bounds = layout size + 10 px on every side |
  | `TextAnnotationTests.cornerResizeScalesFont` | dragging `.bottomRight` to double the height doubles `fontSizeInPixels`; top-left stays fixed |
  | `TextAnnotationTests.multiLineIsTaller` | `"a\nb"` height > `"a"` height; empty string has one line's height |
  | `RedactionAnnotationTests.hitsAnywhereInside` | (50, 50) in (0,0,100,100) hits |
  | `AnnotationDocumentTests.upsertKeepsZOrder` | upsert an existing id keeps its index; a new id appends |
  | `AnnotationDocumentTests.exportRectDefaultsToImage` | no crop → image bounds; crop set → crop |
  | `AnnotationTests.movesEveryKind` (arguments: four kinds) | `moved(by: (5, -3))` shifts `boundsInPixels` by (5, -3) |

- [ ] **Step 2: Run** `make test FILTER=SnapboltEditorTests` → FAIL.
- [ ] **Step 3: Implement** the shapes, `TextLayout` (Core Text `CTFramesetter`, system font at `fontSizeInPixels`, lines split on `\n`), `Annotation` and the document.
- [ ] **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add annotation shapes and document`

---

### Task 4: Editor state, hit testing, history and style preferences

**Files:**
- Create: `Sources/SnapboltEditor/Editing/EditorState.swift`, `AnnotationHitTester.swift`, `EditHistory.swift`, `ToolStylePreferences.swift`
- Test: `Tests/SnapboltEditorTests/AnnotationHitTesterTests.swift`, `EditHistoryTests.swift`, `ToolStylePreferencesTests.swift`, `EditorStateTests.swift`

**Interfaces:**
- Produces:

```swift
struct EditorState: Equatable, Sendable {
    var document: AnnotationDocument
    var selectedID: Annotation.ID?
    var editingTextID: Annotation.ID?
    var tool: EditorTool = .arrow
    var styles: [EditorTool: ToolStyle]
    var selectedAnnotation: Annotation? { get }
    func style(for tool: EditorTool) -> ToolStyle        // styles[tool] ?? .standard
}
enum AnnotationHitTester {
    enum Hit: Equatable { case handle(Annotation.ID, Handle); case body(Annotation.ID) }
    static func hit(at pointInPixels: CGPoint, in document: AnnotationDocument,
                    selectedID: Annotation.ID?, toleranceInPixels: CGFloat) -> Hit?
}
struct EditHistory: Sendable {
    static let limit = 100
    var canUndo: Bool { get }; var canRedo: Bool { get }
    mutating func record(_ previous: AnnotationDocument)       // clears redo, drops the oldest past the limit
    mutating func undo(from current: AnnotationDocument) -> AnnotationDocument?
    mutating func redo(from current: AnnotationDocument) -> AnnotationDocument?
}
@MainActor struct ToolStylePreferences {
    init(defaults: UserDefaults)
    func load() -> [EditorTool: ToolStyle]                     // missing or corrupt entries are omitted
    func save(_ style: ToolStyle, for tool: EditorTool)        // key "editor.style.<rawValue>", JSON
}
```

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `AnnotationHitTesterTests.prefersTopmostShape` | two overlapping rects → the later one's `.body` |
  | `AnnotationHitTesterTests.handlesOnlyForSelection` | point on an unselected rect's corner → `.body`; selected → `.handle(id, .topLeft)` |
  | `AnnotationHitTesterTests.missesEmptyCanvas` | → `nil` |
  | `EditHistoryTests.undoesAndRedoes` | record A, current B: undo → A, redo → B |
  | `EditHistoryTests.newStepClearsRedo` | after undo, `record` → `canRedo == false` |
  | `EditHistoryTests.keepsAtMostOneHundredSteps` | 101 records → 100 undos possible, the 101st returns nil |
  | `ToolStylePreferencesTests.roundTripsPerTool` | save arrow and text styles in a `UserDefaults(suiteName:)`; `load()` returns both |
  | `ToolStylePreferencesTests.ignoresCorruptEntries` | `editor.style.arrow` = `Data("x".utf8)` → `load()` has no `.arrow` key, no crash |
  | `EditorStateTests.fallsBackToStandardStyle` | empty `styles` → `style(for: .text) == .standard` |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** A corrupt preference is logged at `.error` and skipped (comment why the `catch` does not rethrow).
- [ ] **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add editor state, hit testing, undo history and style preferences`

---

### Task 5: Selection and shape drawing tools

**Files:**
- Create: `Sources/SnapboltEditor/Tools/PointerInput.swift`, `ToolInteraction.swift`, `SelectionTool.swift`, `ShapeDrawingTool.swift`
- Test: `Tests/SnapboltEditorTests/SelectionToolTests.swift`, `ShapeDrawingToolTests.swift`

**Interfaces:**
- Produces:

```swift
struct PointerInput: Sendable {
    var pointInPixels: CGPoint; var isShiftDown = false; var clickCount = 1
    var toleranceInPixels: CGFloat; var scale: CGFloat
}
protocol ToolInteraction {
    mutating func began(_ input: PointerInput, in state: EditorState) -> EditorState
    mutating func moved(_ input: PointerInput, in state: EditorState) -> EditorState
    mutating func ended(_ input: PointerInput, in state: EditorState) -> EditorState
}
struct SelectionTool: ToolInteraction {
    static func nudged(_ state: EditorState, by offset: CGVector) -> EditorState
}
struct ShapeDrawingTool: ToolInteraction { init(tool: EditorTool) }   // .arrow, .rectangle, .redaction
```

Behaviour (spec §3.4): `SelectionTool` — handle hit → resize that shape, body hit → select and move, empty → clear selection. `ShapeDrawingTool` — a hit on a shape or the selection's handle delegates to an inner `SelectionTool`; otherwise it inserts a new shape styled from `state.style(for: tool)` (converted with `input.scale`) and updates it live on `moved`; ⇧ snaps arrows to 45° (length kept) and squares rects via `RectResizing.rect(from:to:square:)`; on `ended`, a drag under `3 pt × scale` in both directions removes the shape, otherwise it stays selected.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `ShapeDrawingToolTests.drawsAndSelectsRectangle` | began (10,10), moved (60,40), ended → one rectangle `(10, 10, 50, 30)` with width `4 × scale`, selected |
  | `ShapeDrawingToolTests.ignoresTinyDrags` (scale 2) | began (10,10), ended (14,15) → no annotation |
  | `ShapeDrawingToolTests.snapsArrowToFortyFiveDegrees` | ⇧, (0,0) → (100, 10) → end within 0.01 of (100.50, 0); ⇧, (0,0) → (50, 45) → end on the 45° diagonal |
  | `ShapeDrawingToolTests.squaresRedactionWithShift` | ⇧ drag (0,0)→(40,10) → `(0, 0, 40, 40)` |
  | `ShapeDrawingToolTests.pressOnShapeMovesIt` | existing rect; arrow tool drags its body by (5,5) → no new shape, rect moved |
  | `SelectionToolTests.selectsAndMoves` | drag body by (10, 0) → bounds shifted, `selectedID` set |
  | `SelectionToolTests.resizesByHandle` | selected rect, drag `.bottomRight` → rect grows |
  | `SelectionToolTests.clickOnEmptyClearsSelection` | → `selectedID == nil` |
  | `SelectionToolTests.nudges` | `nudged(by: (0, 10))` moves the selection 10 px; no selection → state unchanged |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add selection and shape drawing tools`

---

### Task 6: Text and crop tools

**Files:**
- Create: `Sources/SnapboltEditor/Tools/TextTool.swift`, `CropTool.swift`
- Test: `Tests/SnapboltEditorTests/TextToolTests.swift`, `CropToolTests.swift`, `ToolInteractionTests.swift`

**Interfaces:**
- Consumes: Task 5 protocol.
- Produces: `extension EditorTool { func makeInteraction() -> any ToolInteraction }` in `Tools/ToolInteraction.swift` (`.select` → `SelectionTool`, `.text` → `TextTool`, `.crop` → `CropTool`, others → `ShapeDrawingTool(tool:)`); `struct TextTool: ToolInteraction`; `struct CropTool: ToolInteraction` with `static func clamped(_ rectInPixels: CGRect, to imageSizeInPixels: CGSize) -> CGRect` (integral, inside the image, at least 1×1).

Behaviour: `TextTool.began` on empty canvas inserts a `TextAnnotation` with an empty string at the point (styled from `.text`), sets `selectedID` and `editingTextID`; on a shape it delegates to `SelectionTool`. `CropTool` works on `document.exportRectInPixels`: handle hit → resize, inside → move (kept inside the image), outside → new frame from the press point; every change goes through `clamped`; on `ended`, a frame equal to the image bounds is stored as `nil`.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `TextToolTests.placesEmptyTextForEditing` | click (30, 40) → one text at (30, 40), `editingTextID == selectedID == its id` |
  | `TextToolTests.pressOnTextMovesIt` | existing text, drag → moved, no new text |
  | `CropToolTests.drawsNewFrame` | image 200×100, drag (10,10)→(60,40) → crop `(10, 10, 50, 30)` |
  | `CropToolTests.clampsToImage` | drag to (500, -20) → crop stays inside `(0, 0, 200, 100)` |
  | `CropToolTests.roundsToWholePixels` | drag to (60.6, 40.2) → integral rect |
  | `CropToolTests.fullImageMeansNoCrop` | resize the frame back to the image bounds → `cropRectInPixels == nil` |
  | `CropToolTests.movesFrameInsideImage` | crop (10,10,50,30), drag inside by (-100, 0) → `x == 0`, size unchanged |
  | `ToolInteractionTests.makesTheToolsInteraction` (arguments: all tools) | `.crop` gives a `CropTool`, `.arrow` a `ShapeDrawingTool`, and so on |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add text and crop tools`

---

### Task 7: Redaction renderer

**Files:**
- Create: `Sources/SnapboltEditor/Rendering/RedactionRenderer.swift`
- Test: `Tests/SnapboltEditorTests/RedactionRendererTests.swift`, `Tests/SnapboltEditorTests/Support/TestPatterns.swift`

**Interfaces:**
- Produces:

```swift
final class RedactionRenderer: Sendable {
    init(source: CGImage, scale: CGFloat, context: CIContext)
    func patch(for redaction: RedactionAnnotation) -> CGImage?   // size of the clamped rect; cached by redaction value
    static func blockSizeInPixels(strength: Double, scale: CGFloat) -> CGFloat
    static func blurRadiusInPixels(strength: Double, scale: CGFloat) -> CGFloat
    var cachedPatchCount: Int { get }                            // for tests
}
// Test support (test target only):
extension CGImage { static func split(width: Int, height: Int) -> CGImage }  // top half red, bottom half blue
extension CGImage { static func stripes(width: Int, height: Int) -> CGImage } // 1 px black/white columns
```

Implementation notes: clamp the area to the image; convert it with `CoordinateConversion.bottomUpRect` for Core Image; `CIPixellate` with `inputCenter` at the area's top-left corner and `inputScale` = block size, or `CIGaussianBlur` with `inputRadius`; both on `clampedToExtent()` and cropped back to the area. The cache is a `Mutex<[RedactionAnnotation: CGImage]>`. If `CIContext` is not `Sendable` in the SDK, store it with a `nonisolated(unsafe)` justification comment (Apple documents `CIContext` as thread-safe), per concurrency rule 9.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `blockSizeFollowsSpecFormula` | strength 40, scale 1 → 15.2; strength 100, scale 2 → 64 |
  | `blurRadiusFollowsSpecFormula` | strength 1, scale 1 → 2.23; strength 100, scale 2 → 50 |
  | `patchHasAreaSize` | redaction (10, 10, 40, 20) → patch 40×20 |
  | `samplesTheAreaUnderTheRedaction` | `split(100×100)`, redaction (0, 0, 100, 20) → every patch pixel is red |
  | `pixelateMakesUniformBlocks` | `stripes(64×64)`, strength 40, scale 1 → pixels (0,0) and (14,0) of the patch are equal |
  | `cachesPatches` | two calls with the same redaction → `cachedPatchCount == 1`; a different strength → 2 |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add pixelate and blur redaction rendering`

---

### Task 8: Annotation renderer and exporter

**Files:**
- Create: `Sources/SnapboltEditor/Rendering/AnnotationRenderer.swift`, `DocumentExporting.swift`, `ImageExporter.swift`, `EditorError.swift`
- Test: `Tests/SnapboltEditorTests/ImageExporterTests.swift`

**Interfaces:**
- Consumes: Tasks 3 and 7.
- Produces:

```swift
struct AnnotationRenderer: Sendable {
    let image: CGImage; let redactions: RedactionRenderer
    func drawImage(in context: CGContext)                         // y-down context in image pixels
    func draw(_ annotations: [Annotation], in context: CGContext)
}
protocol DocumentExporting: Sendable { func export(_ document: AnnotationDocument) throws(EditorError) -> CGImage }
struct ImageExporter: DocumentExporting { init(renderer: AnnotationRenderer) }
enum EditorError: Error, Equatable { case exportFailed }
```

Shapes are drawn as Global Constraints say (arrow shaft + filled head; rect stroke centred, optional fill; text via `TextLayout`, background box first; redaction patch drawn opaque at its rect). The exporter creates an 8-bit premultiplied-last bitmap of `exportRectInPixels` size in the image's colour space (sRGB fallback), flips it to y-down, translates by `−exportRect.origin`, draws image then annotations. A `nil` context or image throws `.exportFailed`.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `exportsImageUnchangedWithoutAnnotations` | `split(40×40)` → pixel (0,0) red, (0,39) blue |
  | `exportKeepsOrientation` | red filled rect at (0, 0, 10, 10) on a grey image → pixel (5, 5) red, (5, 34) grey |
  | `exportsCropSizeAndOffset` | crop (10, 20, 30, 15) → output 30×15; a filled rect at (10, 20, 5, 5) shows at output (2, 2) |
  | `exportsStylesInPixelsAtScaleTwo` | outline rect (10, 10, 80, 80) restyled from a 4 pt red style at scale 2 (8 px, centred on the edge) on a 100×100 grey image → pixel (13, 50) red, (15, 50) grey |
  | `redactionHidesShapesBelowIt` | grey 40×40 image, green filled rect (0, 0, 20, 20), then a redaction over the same area → pixel (10, 10) grey |
  | `shapesAboveRedactionStayVisible` | redaction first, then the green rect → pixel (10, 10) green |
  | `textBackgroundUsesContrast` | white text with background on a grey image → the pixel 2 px inside the box's left edge, at its vertical middle, has every channel < 100 |
  | `preservesColourSpace` | Display P3 source image → `output.colorSpace?.name == CGColorSpace.displayP3` |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): render annotations and export the edited image`

---

### Task 9: Editor model

**Files:**
- Create: `Sources/SnapboltEditor/Window/EditorModel.swift`, `EditorModel+Actions.swift`, `EditorModel+Finishing.swift`
- Test: `Tests/SnapboltEditorTests/EditorModelTests.swift`, `Tests/SnapboltEditorTests/Support/FakeExporter.swift`

**Interfaces:**
- Consumes: Tasks 4–8.
- Produces:

```swift
@MainActor @Observable final class EditorModel {
    enum Phase: Equatable { case editing, exporting, confirmingDiscard, exportFailed, finished }
    private(set) var state: EditorState
    private(set) var mapping: CanvasMapping
    private(set) var phase: Phase
    var canUndo: Bool { get }; var canRedo: Bool { get }; var hasChanges: Bool { get }  // document != initial
    var currentStyle: ToolStyle { get }        // selected shape's style, else the active tool's
    init(capture: CapturedImage, preferences: ToolStylePreferences, exporter: any DocumentExporting,
         onFinish: @escaping @MainActor (EditedImage?) -> Void)
    func setMagnification(_ magnification: CGFloat)
    func selectTool(_ tool: EditorTool)
    func pointerDown(atCanvas point: CGPoint, isShiftDown: Bool, clickCount: Int)
    func pointerDragged(toCanvas point: CGPoint, isShiftDown: Bool)
    func pointerUp(atCanvas point: CGPoint, isShiftDown: Bool)
    // +Actions
    func applyStyle(_ style: ToolStyle)        // clamps; restyles the selection (one undo step); saves as the tool default
    func deleteSelection(); func nudgeSelection(by offset: CGVector)
    func undo(); func redo(); func resetCrop()
    func beginEditingText(_ id: Annotation.ID); func commitText(_ string: String)
    // +Finishing
    func finish(_ destination: EditedImage.Destination) async
    func cancel(); func confirmDiscard(); func keepEditing(); func dismissExportError()
}
```

Rules: pointer points are converted with `mapping.pixelPoint(fromCanvas:)`; tolerance is `mapping.pixels(fromScreenPoints: 6)`. A double-click on a text body with any tool calls `beginEditingText`. History: the document at `pointerDown` is recorded on `pointerUp` only if it changed; text placement is recorded on `commitText` against the document before the text was placed; `commitText("")` removes the text and records nothing for a new text. `finish` runs only in `.editing`, moves to `.exporting`, exports in a `nonisolated` async function, then `.finished` + `onFinish(EditedImage)`, or `.exportFailed` (never calls `onFinish` with the original). `cancel` without changes finishes with `nil`; with changes moves to `.confirmingDiscard`.

- [ ] **Step 1: Write failing tests** (`FakeExporter` returns a fixed 7×5 image or throws `.exportFailed`)

  | Test | Expect |
  |---|---|
  | `uploadFinishesWithExportedImage` | `finish(.upload)` → `onFinish` once with a 7×5 image, destination `.upload`; phase `.finished` |
  | `copyFinishesWithClipboardDestination` | → destination `.clipboard` |
  | `cancelWithoutChangesFinishesWithNil` | → `onFinish(nil)` |
  | `cancelWithChangesAsksFirst` | draw a rect, `cancel()` → phase `.confirmingDiscard`, `onFinish` not called; `keepEditing()` → `.editing`; `cancel()` + `confirmDiscard()` → `onFinish(nil)` |
  | `exportFailureKeepsEditorOpen` | failing exporter → phase `.exportFailed`, `onFinish` never called; `dismissExportError()` → `.editing` |
  | `finishesOnlyOnce` | two concurrent `finish(.upload)` calls, then `cancel()` → `onFinish` called exactly once |
  | `dragIsOneUndoStep` | pointerDown, 50 × pointerDragged, pointerUp → one undo returns to an empty document |
  | `textEditIsOneUndoStep` | text tool click, `commitText("Hi")` → one annotation; `undo()` → none |
  | `emptyTextIsDiscarded` | click, `commitText("")` → no annotation, `canUndo == false` |
  | `restyleAppliesToSelectionAndSaves` | scale 2: select a rect, `applyStyle(width 10)` → its `lineWidthInPixels == 20`; one undo step; `ToolStylePreferences.load()[.rectangle]?.lineWidthInPoints == 10` |
  | `undoRestoresCrop` | crop, `undo()` → `cropRectInPixels == nil` |
  | `convertsCanvasPointsAtScaleTwo` | scale 2, draw from canvas (5,5) to (30,20) → rect `(10, 10, 50, 30)` in pixels |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add editor model with undo, styles and finishing`

---

### Task 10: Canvas

**Files:**
- Create: `Sources/SnapboltEditor/Canvas/EditorCanvasView.swift`, `EditorCanvasView+Mouse.swift`, `EditorCanvasView+Keyboard.swift`, `EditorCanvasView+Drawing.swift`, `TextEditingField.swift`, `ZoomLevels.swift`
- Test: `Tests/SnapboltEditorTests/ZoomLevelsTests.swift`, `TextEditingFieldTests.swift`

**Interfaces:**
- Consumes: `EditorModel` (Task 9), `AnnotationRenderer` (Task 8).
- Produces:

```swift
enum ZoomCommand: Sendable { case zoomIn, zoomOut, fit, actualSize }        // in ZoomLevels.swift
enum ZoomLevels {
    static let steps: [CGFloat] = [0.1, 0.25, 0.5, 0.75, 1, 1.5, 2, 3, 4, 6, 8]
    static let nearestNeighbourAbove: CGFloat = 2
    static func zoomedIn(from magnification: CGFloat) -> CGFloat
    static func zoomedOut(from magnification: CGFloat) -> CGFloat
    static func fitting(_ contentSizeInPoints: CGSize, in availableSize: CGSize) -> CGFloat   // clamped 0.1…8
}
@MainActor final class EditorCanvasView: NSView {   // isFlipped = true; frame = image size in points
    init(model: EditorModel, renderer: AnnotationRenderer, onZoom: @escaping @MainActor (ZoomCommand) -> Void,
         onFinish: @escaping @MainActor (EditedImage.Destination) -> Void)
    func commitTextEditing()                         // called before finishing or cancelling
}
@MainActor final class TextEditingField: NSTextView {
    static func frame(for text: TextAnnotation, mapping: CanvasMapping) -> CGRect   // == mapping.canvasRect(fromPixels: text.boundsInPixels)
}
```

Notes: redraw by re-arming `withObservationTracking` on `model.state` and `model.mapping`; `draw(_:)` scales the context by `1 / scale`, calls `renderer.drawImage` and `renderer.draw`, then `+Drawing` adds crop dimming (50% black over the outside with the crop tool, canvas background colour otherwise) and 8-screen-point handles. Interpolation `.none` above `nearestNeighbourAbove`. `+Keyboard` implements every shortcut in Global Constraints plus `@objc undo(_:)` / `redo(_:)` with `NSMenuItemValidation` so the main menu's Edit items work; tool letters and arrows are ignored while `TextEditingField` is first responder. `TextEditingField` uses the system font at `fontSizeInPixels / scale` points and calls `model.commitText` on Escape and on resigning first responder.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `ZoomLevelsTests.stepsInAndOut` | from 1 → in 1.5, out 0.75; from 8 → in 8; from 0.1 → out 0.1; from 1.2 → in 1.5 |
  | `ZoomLevelsTests.fitsContent` | content 2000×1000 in 1000×1000 → 0.5; 10×10 in 1000×1000 → 8 |
  | `TextEditingFieldTests.frameMatchesLayout` | scale 2, text at (40, 60), font 48 px → `frame(for:mapping:) == mapping.canvasRect(fromPixels: text.boundsInPixels)` |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add the editing canvas`

---

### Task 11: Toolbar, window and `EditorController`

**Files:**
- Create: `Sources/SnapboltEditor/Toolbar/EditorToolbarView.swift`, `ToolPickerView.swift`, `StyleControlsView.swift`, `Window/EditorWindowLayout.swift`, `Window/EditorWindowController.swift`, `EditorController.swift`
- Test: `Tests/SnapboltEditorTests/EditorWindowLayoutTests.swift`

**Interfaces:**
- Consumes: Tasks 9 and 10.
- Produces:

```swift
struct EditorWindowLayout: Equatable {
    static let toolbarHeight: CGFloat = 52
    let contentSize: CGSize; let magnification: CGFloat
    static func initial(imageSizeInPoints: CGSize, visibleFrame: CGRect) -> EditorWindowLayout
}
@MainActor final class EditorWindowController: NSObject, NSWindowDelegate {
    init(model: EditorModel, renderer: AnnotationRenderer, layout: EditorWindowLayout)
    func show()                                       // on the screen under the mouse
}
/// Shows the annotation editor for a capture.
@MainActor public final class EditorController: ImageEditing {
    /// Creates a controller that remembers tool styles in `defaults`.
    public init(defaults: UserDefaults = .standard)
    /// Opens a new editor window and returns when it closes.
    public func edit(_ capture: CapturedImage) async -> EditedImage?
}
```

Layout rule: if the image fits in 85% of the visible frame (minus the toolbar height), magnification 1 and content = image + toolbar; otherwise content = 85% of the frame and magnification = `ZoomLevels.fitting`. Window: titled `Snapbolt Editor`, resizable, `collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]`, `NSApp.activate()`, `makeKeyAndOrderFront`; toolbar in an `NSHostingView` above an `NSScrollView` (`allowsMagnification`, 0.1…8) whose document view is the canvas; magnification changes go to `model.setMagnification`. `windowShouldClose` calls `canvas.commitTextEditing()` + `model.cancel()` and returns `false`; sheets are shown when `model.phase` becomes `.confirmingDiscard` or `.exportFailed`; the window closes on `.finished`. `EditorController` creates one `CIContext` per edit, keeps each window controller in a `[UUID: EditorWindowController]` until its `onFinish`, logs open/finish (destination)/cancel and the image size, never text or image data. Toolbar: tool buttons with SF Symbols and the key in the help tag; `StyleControlsView` shows the controls of spec §3.3 for `model.currentStyle` (SwiftUI `ColorPicker` with `supportsOpacity: true` bridged through `RGBAColor(cgColor:)`; numeric fields with steppers; Pixelate/Blur segmented picker and strength slider with the redaction help text; crop size label and `Reset`); undo/redo buttons; zoom menu (Fit, 50%, 100%, 200%); `Cancel`, `Copy`, `Upload` (prominent), all disabled with a small progress indicator while `model.phase == .exporting`. Buttons carry no keyboard shortcuts of their own.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `EditorWindowLayoutTests.smallImageOpensAtActualSize` | 800×600 image, frame 1920×1080 → magnification 1, content 800 × (600 + 52) |
  | `EditorWindowLayoutTests.largeImageIsFitted` | 3000×2000, frame 1920×1080 → content 1632×918, magnification = `fitting(3000×2000, in: 1632×866)` |

- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(editor): add editor window, toolbar and controller`

---

### Task 12: Workflow editor step and app wiring

**Files:**
- Modify: `Sources/SnapboltWorkflow/CaptureWorkflow.swift`, `CaptureWorkflow+Dependencies.swift`; create `CaptureWorkflow+Editing.swift`
- Modify: `Tests/SnapboltWorkflowTests/WorkflowHarness.swift`; test: `Tests/SnapboltWorkflowTests/CaptureWorkflowEditingTests.swift`
- Modify: `App/AppEnvironment.swift` (pass `editor: EditorController()`)

**Interfaces:**
- Consumes: Task 1 (`ImageEditing`, `FakeImageEditor`), Task 11 (`EditorController`).
- Produces: `CaptureWorkflow.Dependencies.init(capturer:selector:editor:encoder:saver:uploader:settings:clipboard:notifier:history:now:)` with `editor: any ImageEditing`; `WorkflowHarness.init(…, display: FrozenDisplay = Self.display, opensEditor: Bool = false, editResult: EditedImage? = nil)` exposing `editor: FakeImageEditor`.

Flow (spec §4.3): `capture(_:)` returns `CapturedImage?` with the selected display's `scale`; preferences are read once and passed to the local save; editor off → upload the unedited image; on → `edit`, `nil` → log "Editor cancelled" and return; `.clipboard` → encode, save locally, `clipboard.writeImage`, return; `.upload` → Phase 1 path with the edited image.

- [ ] **Step 1: Write failing tests** (edited image = `CGImage.solid(width: 7, height: 5)`)

  | Test | Expect |
  |---|---|
  | `editorOffNeverOpensEditor` | default harness, `.region` → `editor.receivedCaptures.isEmpty`; link copied as before |
  | `uploadsEditedImage` | `opensEditor: true`, result `.upload` → `encoder.encodedSizes == [7×5]`; link copied; history has the entry |
  | `copyOnlySkipsUpload` | result `.clipboard`, `saveLocally: true` → `writtenImages.count == 1`, `uploadedImages.isEmpty`, `history.entries.isEmpty`, saver called once, notifier untouched |
  | `cancelledEditLeavesNoTrace` | result `nil`, `saveLocally: true` → nothing encoded, saved, uploaded, copied or notified |
  | `fullScreenOpensEditor` | `.fullScreen`, `opensEditor: true` → one received capture of 100×100 |
  | `passesDisplayScale` | `display: .fixture(width: 200, height: 200, scale: 2)`, region → received scale 2 |
  | `twoEditorsFinishIndependently` | editor suspends; start run A, wait until 1 capture received; start run B, wait until 2; `resumeNext(.upload)` twice → two links on the clipboard |

- [ ] **Step 2: Run** `make test FILTER=SnapboltWorkflowTests` → FAIL.
- [ ] **Step 3: Implement** the workflow change; keep `CaptureWorkflow.swift` and every function inside the limits by putting the editor step and the clipboard ending in `CaptureWorkflow+Editing.swift`. Pass `EditorController()` in `AppEnvironment`.
- [ ] **Step 4: Run** `make test` → PASS (all Phase 1 workflow tests unchanged); `make build` → `** BUILD SUCCEEDED **`; `make lint` → clean.
- [ ] **Step 5: Commit** — `feat(workflow): open the editor between capture and upload`

---

### Task 13: Edit After Capture setting, menu item and docs

**Files:**
- Modify: `Sources/SnapboltSettings/SettingsStore.swift`, `General/GeneralSettingsModel.swift`, `General/GeneralSettingsView.swift`
- Test: `Tests/SnapboltSettingsTests/SettingsStoreTests.swift`, `GeneralSettingsModelTests.swift`
- Modify: `App/AppEnvironment.swift`, `App/AppDelegate.swift`, `App/Windows/SettingsWindowController.swift`, `App/MenuBar/MenuBarController.swift`; create `App/MenuBar/ToggleMenuItem.swift`
- Modify: `docs/architecture.md`, `docs/testing.md`, `CHANGELOG.md`, `README.md`

**Interfaces:**
- Produces: `SettingsStore` key `capture.opensEditor`; `GeneralSettingsModel.opensEditor: Bool` (saved on change); `AppEnvironment.generalSettings: GeneralSettingsModel` (the only instance); `MenuBarController.Actions` gains `isEditorEnabled: @MainActor () -> Bool` and `toggleEditor: @MainActor () -> Void`; `ToggleMenuItem(title:isOn:toggle:)` — an `NSMenuItem` that is its own target and sets its `state` in `validateMenuItem(_:)`, which AppKit calls every time the menu opens.

- [ ] **Step 1: Write failing tests**

  | Test | Expect |
  |---|---|
  | `SettingsStoreTests.freshStoreHasDefaults` (existing, unchanged) | still passes — `opensEditor` defaults to `false` |
  | `SettingsStoreTests.savesOpensEditor` | save preferences with `opensEditor: true` → read back `true` |
  | `GeneralSettingsModelTests.togglingEditorSavesIt` | `model.opensEditor = true` → `store.currentCapturePreferences().opensEditor` |
  | `GeneralSettingsModelTests.keepsEditorWhenChangingFolder` | `opensEditor = true`, then change `folder` → still `true` |

- [ ] **Step 2: Run** `make test FILTER=SnapboltSettingsTests` → FAIL.
- [ ] **Step 3: Implement** the store, model and the `Editor` section in `GeneralSettingsView`. In the app: create `generalSettings` in `AppEnvironment`, use it in `SettingsWindowController`, and add `ToggleMenuItem("Edit After Capture")` below the two capture items, wired to `generalSettings.opensEditor`.
- [ ] **Step 4: Update docs** — `architecture.md`: module table row for `SnapboltEditor`, the dependency diagram, the two new coordinate spaces, "Data on disk" rows, Phase 2 sentence now past tense; `testing.md`: the Editor checklist from spec §8; `CHANGELOG.md` Unreleased › Added: "Optional annotation editor (arrow, rectangle, text, pixelate/blur, crop) between capture and upload, turned on with Edit After Capture."; README feature list.
- [ ] **Step 5: Verify** — `make test`, `make lint`, `make build` all green. Run the app and work through the Editor section of `docs/testing.md` plus the Phase 1 "Capture and overlay" and "Upload and results" sections with the editor off. Note results for the PR description.
- [ ] **Step 6: Commit** — `feat(settings): add Edit After Capture to settings and the menu`, then `docs: document the annotation editor` for the docs.
