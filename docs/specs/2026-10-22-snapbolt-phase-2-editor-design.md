# Snapbolt — Phase 2 Design: Annotation Editor

- **Status:** Approved
- **Date:** 2026-10-22
- **Owner:** @siracozmen01
- **Builds on:** [Phase 1 design](2026-10-21-snapbolt-phase-1-design.md) (merged)

## 1. Summary

Phase 2 adds an optional annotation editor between capture and upload. When **Edit After Capture**
is on, every capture opens in an editor window where the user can draw arrows and rectangles, add
text, hide sensitive areas (pixelate or blur) and crop. The user then uploads the result, copies it
without uploading, or cancels the capture.

With the option off (the default) Snapbolt behaves exactly as in Phase 1.

## 2. Goals and non-goals

### Goals

- A menu bar toggle and a matching settings toggle, **Edit After Capture**, off by default.
- An editor window with five tools: arrow, rectangle, text, redaction (pixelate or blur) and crop,
  plus a select tool.
- Editable objects like ShareX: every shape can be selected, moved, resized by its handles, restyled
  and deleted after it is drawn; full undo and redo.
- Free styling: any colour (with opacity) from the system colour panel, numeric line width and font
  size.
- Three ways out: **Upload** (the Phase 1 pipeline), **Copy** (clipboard and local copy, no upload)
  and **Cancel** (the capture is discarded, like Escape in the overlay).
- What the editor shows is exactly what is exported: one renderer draws both.
- The editor lives in a new module, `SnapboltEditor`, that depends only on `SnapboltCore`. The
  workflow reaches it through a new Core protocol, `ImageEditing`.

### Non-goals (Phase 2)

- Copy and paste of shapes, z-order commands (bring to front), multiple selection.
- Freehand drawing, numbered step markers, highlighter, emoji or image stickers.
- Opening existing image files in the editor, or editing an upload from history.
- An editor for recordings (Phase 3).
- A per-capture override in the overlay; the toggle is the only switch.

## 3. User-facing behaviour

### 3.1 Turning the editor on

- **Menu bar:** a checkable item **Edit After Capture** below the two capture items.
- **Settings › General:** a new section **Editor** with the toggle **Open the editor after each
  capture**.
- Both show the same value and change the same preference (`capture.opensEditor` in
  `UserDefaults`, default `false`). Changing one is reflected by the other immediately.
- The toggle applies to region, window and full-screen captures. Full screen plus crop in the editor
  is also the fallback for games that keep the cursor captured (Phase 1 spec §13).

### 3.2 The editor window

- A standard, resizable window titled **Snapbolt Editor**, opened on the display under the mouse
  and brought to the front, also over apps in native full screen.
- Initial zoom is 100% (one image point per screen point) when the image fits in 85% of the
  display's visible frame; otherwise the image is fitted to that size.
- Several editor windows may be open at once (one per capture). New captures are allowed while an
  editor is open; the overlay's "one selection at a time" rule is unchanged.

Layout, top to bottom:

```
┌───────────────────────────────────────────────────────────────────────────────────────┐
│ [Select V][Arrow A][Rect R][Text T][Redact B][Crop C] │ style controls │ ↶ ↷ │ 100% ▾ │
│                                                        Cancel   Copy   [ Upload ]      │
├───────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                       │
│                         canvas (scrollable, zoomable)                                 │
│                                                                                       │
└───────────────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Style controls

The controls follow the active tool, or the selected shape when there is one.

| Tool | Controls | Range | Default |
|---|---|---|---|
| Arrow | Colour, line width | 1–40 pt | red, 4 pt |
| Rectangle | Colour, line width, filled | 1–40 pt | red, 4 pt, outline |
| Text | Colour, font size, background box | 8–200 pt | red, 24 pt, no background |
| Redact | Mode (Pixelate / Blur), strength | 1–100 | Pixelate, 40 |
| Crop | Size label in pixels, **Reset** | — | — |

- Colour opens the system colour panel with opacity.
- Sizes are in points, as seen at 100% zoom; shapes store pixels (`points × capture scale`), so a
  4 pt arrow looks the same on Retina and non-Retina captures.
- Changing a style while a shape is selected restyles that shape (one undo step) and also becomes
  that tool's default.
- The last style of each tool is remembered across captures and launches.
- The redaction tool's help text says: "Use Pixelate for sensitive data; weak blur can sometimes be
  reversed."

### 3.4 Tools

**Shape tools (Arrow, Rectangle, Redact)**

- Dragging on empty canvas draws a new shape. With ⇧, arrows snap to 45° steps and rectangles and
  redaction areas become squares.
- A drag shorter than 3 pt in both directions draws nothing.
- The new shape is selected; the tool stays active.
- Pressing on an existing shape or one of its handles selects, moves or resizes it instead of
  drawing.

**Select tool**

- Click selects the topmost shape under the pointer; dragging its body moves it; dragging a handle
  resizes it; clicking empty canvas clears the selection.
- Handles: arrows have one at each end; rectangles and redaction areas have eight; text has four
  corner handles that scale its font size.
- Arrow keys nudge the selected shape by 1 px, with ⇧ by 10 px. ⌫ or ⌦ deletes it.

**Text tool**

- Click places a text field at that point, using the current style. Return inserts a new line.
- Escape or a click outside commits the text. Empty text is discarded.
- Double-click on an existing text shape (with any tool) edits it.

**Crop tool**

- Shows a crop frame (the current crop, or the whole image) with eight handles; the area outside is
  dimmed. Dragging on empty canvas outside the frame draws a new frame.
- The frame is kept inside the image and is at least 1 × 1 px.
- With another tool active, the area outside the crop is painted with the canvas background.
- **Reset** removes the crop. Cropping never deletes pixels or shapes; it is applied on export and
  undone with ⌘Z.

### 3.5 Keyboard and zoom

| Keys | Action |
|---|---|
| V, A, R, T, B, C | Select tool (when no text field is being edited) |
| ⌘Z / ⇧⌘Z | Undo / redo (also via the main menu's Edit › Undo / Redo) |
| ⌘+ / ⌘− | Zoom in / out |
| ⌘0 / ⌘1 | Fit to window / 100% |
| Pinch | Zoom (10%–800%) |
| ⌘Return | Upload |
| ⇧⌘C | Copy |
| Escape | Commit the text being edited; otherwise Cancel |

### 3.6 Leaving the editor

| Action | Trigger | Result |
|---|---|---|
| Upload (default button) | ⌘Return, **Upload** | The edited image continues through Phase 1: encode, local copy, upload, link on the clipboard, history, notification. |
| Copy | ⇧⌘C, **Copy** | The edited image is encoded, the local copy is saved (when enabled) and the image is put on the clipboard. No upload, no history entry, no notification. |
| Cancel | Escape, **Cancel**, the window's close button | If anything changed, a sheet asks **Discard this capture?** (Discard / Keep Editing). The capture ends silently: nothing saved, nothing uploaded, no notification. |

## 4. Architecture

### 4.1 Module graph

```
                 ┌──────────────► SnapboltCore ◄──────────────┐
                 │                     ▲                       │
App ──► SnapboltWorkflow ──────────────┘          Capture, Overlay, Upload, Settings,
 │                                                Hotkeys, History, System, Editor
 └──────────────────────────────────────────────► (constructed by the App target only)
```

| Module | Responsibility | May import |
|---|---|---|
| `SnapboltEditor` (new) | Annotation document, editing tools, rendering and export, the editor window | Core, AppKit, SwiftUI, CoreImage, CoreText |

The existing dependency rules apply unchanged: `SnapboltEditor` imports no other feature module;
`SnapboltWorkflow` knows only `ImageEditing`; only `App/AppEnvironment.swift` creates
`EditorController`. No new third-party dependency, so no ADR is needed.

### 4.2 Core additions

```swift
/// A cropped capture and the scale of the display it came from.
public struct CapturedImage: Sendable {
    public let image: CGImage
    /// Pixels per point of the source display.
    public let scale: CGFloat
}

/// The result of editing a capture.
public struct EditedImage: Sendable {
    public enum Destination: Sendable { case upload, clipboard }
    public let image: CGImage
    public let destination: Destination
}

/// Lets the user annotate a capture before it is saved and uploaded.
@MainActor
public protocol ImageEditing {
    /// Shows the editor and returns the edited image, or `nil` if the user cancelled.
    func edit(_ capture: CapturedImage) async -> EditedImage?
}
```

- `CapturePreferences` gains `opensEditor: Bool`; its initializer defaults it to `false`.
- `Selection` gains `displayID` (computed), used by the workflow to find the capture's scale and by
  `ImageCropper` in place of its private helper.
- `Geometry/CanvasMapping.swift`: pure conversions between image pixels and canvas points
  (see §4.5).

Cancellation is a `nil` result, as with `SelectionPresenting`. The editor never throws: export
failures are handled inside the editor (see §7).

### 4.3 Workflow

`CaptureWorkflow.run(_:)` becomes:

1. Capture as today; `capture(_:)` returns `CapturedImage?` (the crop plus the selected display's
   scale). `nil` still means "cancelled in the overlay".
2. Read `CapturePreferences` once.
3. If `opensEditor` is off, continue with `.upload` and the unedited image.
4. If it is on, `await editor.edit(captured)`:
   - `nil` → log "Editor cancelled" and return. No notification, nothing saved.
   - `.upload` → continue as Phase 1 with the edited image.
   - `.clipboard` → encode, save the local copy, write the image to the clipboard, return.
5. Encode, save the local copy (using the preferences from step 2), upload and copy the link, as
   today.

- `Dependencies` gains `editor: any ImageEditing`.
- The editor step and the clipboard-only ending live in `CaptureWorkflow+Editing.swift`, keeping
  `CaptureWorkflow.swift` well under the size limits.
- `isSelecting` is still set only while the overlay is open.

### 4.4 Settings and menu

- `SettingsStore` reads and writes `capture.opensEditor` together with the other capture
  preferences.
- `GeneralSettingsModel` gains `opensEditor` (saved on change) and `GeneralSettingsView` gains the
  **Editor** section.
- `AppEnvironment` owns the single `GeneralSettingsModel`; `SettingsWindowController` uses it
  instead of creating its own, and the menu toggles it. The menu item sets its check mark from the
  model whenever the menu opens (in `validateMenuItem(_:)`, which AppKit calls on every opening).

### 4.5 Coordinate spaces

Two spaces are added to the table in [architecture.md](../architecture.md#coordinate-spaces):

| Space | Origin | Unit | Used by |
|---|---|---|---|
| Image pixels | Top-left of the captured (cropped) image, y down | pixels | Annotation document, renderer, export |
| Canvas points | Top-left of the editor's canvas view (flipped), y down | points | Mouse events, canvas drawing |

- `canvas = pixels / scale`. Zoom is the scroll view's magnification and is applied by AppKit; it is
  only needed to keep handles and hit tolerances a constant size on screen
  (`toleranceInPixels = 6 / magnification × scale`).
- These conversions live in `SnapboltCore/Geometry/CanvasMapping.swift` and nowhere else.
- Shapes, line widths, font sizes and the crop rect are stored in image pixels, so export is
  independent of zoom.

### 4.6 Inside `SnapboltEditor`

```
Sources/SnapboltEditor/
├── EditorController.swift        ImageEditing; opens one EditorWindowController per edit()
├── Logging.swift
├── Document/
│   ├── AnnotationDocument.swift  image size, [Annotation] (z-order), crop rect
│   ├── Annotation.swift          id + Kind (arrow, rectangle, text, redaction)
│   ├── ArrowAnnotation.swift     ┐
│   ├── RectangleAnnotation.swift │ geometry and style of one shape; bounds, hit test,
│   ├── TextAnnotation.swift      │ handles, moved(by:), resized(_:to:)
│   ├── RedactionAnnotation.swift ┘
│   ├── RGBAColor.swift           Sendable, Equatable colour value
│   └── EditHistory.swift         undo/redo stacks of documents, limit 100
├── Editing/
│   ├── EditorState.swift         document, selection, active tool, styles
│   ├── EditorTool.swift          .select, .arrow, .rectangle, .text, .redaction, .crop
│   ├── ToolStyle.swift           per-tool style values and ranges
│   ├── ToolStylePreferences.swift  remembers styles in UserDefaults (editor.* keys)
│   ├── Handle.swift              handle positions and their resize behaviour
│   └── AnnotationHitTester.swift topmost shape / handle under a point
├── Tools/
│   ├── ToolInteraction.swift     protocol: began / moved / ended → new EditorState
│   ├── ShapeDrawingTool.swift    arrow, rectangle and redaction drawing
│   ├── SelectionTool.swift       select, move, resize, nudge
│   ├── TextTool.swift            place and re-edit text
│   └── CropTool.swift            crop frame editing and clamping
├── Rendering/
│   ├── AnnotationRenderer.swift  draws shapes into a CGContext in image pixels
│   ├── RedactionRenderer.swift   Core Image pixelate / blur, with RedactionCache
│   ├── TextLayout.swift          Core Text line layout and bounds
│   └── ImageExporter.swift       final CGImage: crop, image, shapes
├── Canvas/
│   ├── EditorCanvasView.swift    NSView document view inside an NSScrollView
│   ├── EditorCanvasView+Mouse.swift
│   ├── EditorCanvasView+Keyboard.swift
│   ├── EditorCanvasView+Drawing.swift   handles, crop dimming
│   └── TextEditingField.swift    in-place NSTextView for the text tool
├── Toolbar/
│   ├── EditorToolbarView.swift   SwiftUI, hosted in the window
│   ├── ToolPickerView.swift
│   └── StyleControlsView.swift
└── Window/
    ├── EditorWindowController.swift  window, sheets, activation
    └── EditorModel.swift             @MainActor @Observable: state, history, actions
```

- The [implementation plan](../plans/2026-10-22-snapbolt-phase-2.md) refines this layout to keep
  every folder at eight files or fewer (for example, `EditHistory` moves to `Editing/` and
  `RGBAColor` to `Rendering/`); the plan's file list is authoritative.
- `Document/`, `Editing/`, `Tools/` and `Rendering/` are pure logic over value types and are where
  the unit tests concentrate. `Canvas/`, `Toolbar/` and `Window/` are thin UI.
- `EditorModel` is the one place that mutates state: tools return new states, the model commits
  them to `EditHistory` at the end of a gesture (mouse up, text commit, style change), not on every
  drag event. If it grows past the limits, its actions move to `EditorModel+Actions.swift`.
- `EditorController` keeps each open window controller alive until its edit finishes; there is no
  global editor state.
- `ToolStylePreferences` receives its `UserDefaults` through its initializer.

### 4.7 Document model

```swift
struct AnnotationDocument: Equatable, Sendable {
    let imageSizeInPixels: CGSize
    var annotations: [Annotation]     // later entries are drawn on top
    var cropRectInPixels: CGRect?     // nil = whole image
}

struct Annotation: Identifiable, Equatable, Sendable {
    let id: UUID
    var kind: Kind
    enum Kind: Equatable, Sendable {
        case arrow(ArrowAnnotation)          // start, end, color, lineWidth
        case rectangle(RectangleAnnotation)  // rect, color, lineWidth, isFilled
        case text(TextAnnotation)            // string, origin, color, fontSize, hasBackground
        case redaction(RedactionAnnotation)  // rect, mode, strength
    }
}
```

Undo and redo store whole documents. Documents are small (a few hundred bytes per shape, the image
is not part of them), so 100 steps are cheap and undo is trivially correct, crop included.

## 5. Rendering and export

### 5.1 One renderer

`AnnotationRenderer` draws a document's shapes into a `CGContext` whose user space is image pixels.

- The canvas applies its pixel-to-point transform, draws the image, calls the renderer, then draws
  selection handles and crop dimming on top.
- `ImageExporter` calls the same renderer at full resolution, without handles or dimming.

Drawing order: the image, then shapes in document order.

### 5.2 Shapes

- **Arrow:** a line and a filled triangular head; head length `max(lineWidth × 4, 10 px)`. The line
  stops at the base of the head so translucent colours do not overlap.
- **Rectangle:** stroke centred on the rect's edges; when filled, the interior is filled with the same
  colour.
- **Text:** `TextLayout` lays out lines with Core Text and the system font. The same layout gives
  the drawing, the hit-test bounds and the size of the text field while editing. With a background,
  a rounded box is drawn behind the text: black at 60% for light text, white at 80% for dark text
  (by relative luminance).
- **Redaction:** see §5.3.

### 5.3 Redaction

- A redaction area always samples the **original image**, not the shapes below it. The patch is
  opaque, so it hides both the original content and any shapes under it; shapes above it are drawn
  normally.
- Because the original image never changes, each patch is cached by `(rect, mode, strength)` in
  `RedactionCache`. Moving other shapes does not re-run Core Image.
- **Pixelate:** `CIPixellate`, block size `(4 + 28 × strength / 100) pt × scale`, aligned to the
  area's origin.
- **Blur:** `CIGaussianBlur`, radius `(2 + 23 × strength / 100) pt × scale`.
- Both clamp the input to its extent before filtering and crop the result to the area, so edges are
  not transparent.
- One `CIContext` per editor session, created by `EditorController` and passed in.

### 5.4 Export

- A bitmap context the size of the crop rect (or the image), 8 bits per component, premultiplied
  alpha, in the captured image's colour space (sRGB if it has none), so Display P3 captures do not
  shift colour.
- The image and shapes are drawn translated by `−crop.origin`.
- Export runs in a `nonisolated async` function (document and image are `Sendable`), off the main
  actor; the window shows a progress state while it runs.
- The resulting `CGImage` goes back to the workflow, which encodes it as PNG as before.

### 5.5 Canvas details

- Above 200% zoom the image is drawn with nearest-neighbour interpolation so pixels stay sharp for
  precise cropping.
- Handles are 8 pt squares on screen at any zoom.

## 6. Data on disk

| Data | Location |
|---|---|
| Edit After Capture | `UserDefaults`, `capture.opensEditor` |
| Last style per tool | `UserDefaults`, `editor.style.<tool>` (JSON-encoded style) |

Nothing else is stored. Edited images follow the Phase 1 rules for local copies.

## 7. Error handling

- **Export failure** (for example, a bitmap context cannot be created): the editor shows an alert
  sheet "Could not export the edited image." and stays open, so the user can retry, copy or cancel.
  It **never** falls back to the unedited image, which could leak an area the user redacted.
  The failure is an `EditorError.exportFailed` internal to `SnapboltEditor` and is logged.
- `ImageEditing.edit` does not throw, so the workflow's error mapping is unchanged.
- Logging: the editor logs open, finish (with destination) and cancel, and the image size. It never
  logs text content or image data.

## 8. Testing

Swift Testing, hand-written fakes, no UI automation.

| Target | Covers |
|---|---|
| `SnapboltCoreTests` | `CanvasMapping` round trips at scale 1 and 2 and several magnifications; `Selection.displayID` |
| `SnapboltWorkflowTests` | Editor off: Phase 1 behaviour unchanged and the editor is never called. On + `.upload`: the uploaded and saved image is the edited one. On + `.clipboard`: image on the clipboard, local copy saved, no upload, no history, no notification. On + `nil`: nothing saved, no notification. Full-screen capture opens the editor. The editor receives the selected display's scale. |
| `SnapboltSettingsTests` | `opensEditor` defaults to `false`, is saved and read back; `GeneralSettingsModel` persists the toggle |
| `SnapboltEditorTests` | Per shape (parameterized): bounds, hit testing, handles, move, resize. ⇧ constraints, minimum drag size, crop clamping. `EditHistory`: undo, redo, limit, a new step clears redo. Tool state transitions for each tool. `ToolStylePreferences` with a temporary `UserDefaults(suiteName:)`. `ImageExporter`: output size, crop offset, a known pixel's colour. `RedactionRenderer`: pixels outside the area unchanged, uniform pixelate blocks, cache hits. `EditorModel`: each exit produces the right result; cancelling with changes asks for confirmation. |

`SnapboltTestSupport` gains `FakeImageEditor` (returns a configured result and records the captures
it received) and `CGImage.pixel(atX:y:)` for pixel assertions.

The canvas, toolbar and window are covered by a new **Editor** section in
[docs/testing.md](../testing.md):

- Editor opens on the display under the mouse, in front of other apps and of Minecraft in native
  full screen.
- Each tool draws, selects, moves, resizes, restyles and deletes; ⇧ constraints work.
- Text: place, multi-line, re-edit by double-click, Escape commits.
- Crop: handles, reset, undo; the uploaded image matches the crop exactly.
- Uploaded image is identical to what the editor showed (Retina and non-Retina captures).
- Pixelated text is unreadable at the default strength.
- Zoom shortcuts and pinch; editing stays smooth on a 5K capture.
- Copy and Cancel behave as in §3.6; two editors open at once work independently.
- Edit After Capture in the menu and in Settings stay in sync and survive a relaunch.

## 9. Documentation and project changes

- `Package.swift`: add `SnapboltEditor` to `featureModules` and `testedModules`.
- `docs/architecture.md`: module table, dependency diagram, coordinate spaces, "Data on disk".
- `CHANGELOG.md` (Unreleased) and README feature list.
- `docs/testing.md`: the Editor checklist above.

## 10. Risks

| Risk | Mitigation |
|---|---|
| The editor window does not come to the front over a full-screen game | `.fullScreenAuxiliary` and `.moveToActiveSpace`, app activation as in the overlay; manual check with Minecraft. Fallback: `.floating` window level. |
| Slow redraws on large captures | Redaction patches cached; image drawn as a layer-backed bitmap; shapes are cheap vector drawing. Checked on a 5K capture. |
| Text field and rendered text differ in size or position | Both use `TextLayout`; unit test compares the field's frame with the layout's bounds. |
| Weak blur can be reversed | Pixelate is the default redaction mode; help text recommends it for sensitive data. |
| Export silently drops edits | Export failures keep the editor open; never fall back to the original image. |

## 11. Acceptance criteria

1. With Edit After Capture off, the capture pipeline behaves exactly as in Phase 1 and the existing
   tests pass unchanged.
2. The menu item and the settings toggle always show the same value, which survives a relaunch.
3. ⌥⇧4 → select → arrow, rectangle, text, pixelate and crop → Upload: the image behind the link is
   pixel-identical to the editor's content within the crop.
4. Copy puts the edited image on the clipboard and saves the local copy without uploading; Cancel
   leaves no trace.
5. Text under a default-strength pixelate area is unreadable.
6. The editor opens in front of Minecraft in native full screen.
7. Two editors can be open at once and finish independently.
8. CI is green and no file exceeds the limits in
   [docs/conventions/file-organization.md](../conventions/file-organization.md).
