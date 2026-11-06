# Testing Snapbolt

Automated tests cover the logic (see [conventions/testing.md](conventions/testing.md)). Screen
capture, the overlay and system integration need the Screen Recording permission and real displays,
so they are checked by hand with the list below before every release and in any PR that touches
`SnapboltCapture`, `SnapboltOverlay`, `SnapboltSystem` or the app target.

## Automated

```bash
make test     # package tests
make lint     # SwiftLint + swift-format
```

## Debugging a capture

Snapbolt logs each step of a capture under the subsystem `io.github.siracozmen01.Snapbolt`:

```bash
/usr/bin/log stream --info --debug --predicate 'subsystem == "io.github.siracozmen01.Snapbolt"'
```

Use the full path: in zsh, `log` is a shell builtin. Debug builds also start a region capture when
they receive a distributed notification, so a capture can be triggered from Terminal:

```bash
swift -e 'import Foundation; DistributedNotificationCenter.default().postNotificationName(.init("io.github.siracozmen01.Snapbolt.debugCapture"), object: nil, userInfo: nil, deliverImmediately: true)'
```

## Manual checklist

Copy the relevant sections into the PR description and tick them.

### Capture and overlay

- [ ] ⌥⇧4 shows the frozen overlay on every display; the frozen image matches the moment of the key press.
- [ ] Dragging selects a region; the size label shows pixels; the magnifier follows the cursor.
- [ ] Hovering highlights the window under the cursor; clicking selects exactly that window's frame.
- [ ] Return selects the display under the cursor; Escape closes the overlay with no notification.
- [ ] Pressing ⌥⇧4 again while the overlay is open does nothing.
- [ ] ⌥⇧3 captures the display under the cursor without an overlay.

### Games (the reason Snapbolt exists)

- [ ] Minecraft, windowed, in game (cursor locked): ⌥⇧4 shows the overlay and the cursor moves freely.
- [ ] Minecraft, native full screen: same as above; the overlay appears on top of the game's space.
- [ ] After capturing, returning to the game works normally.

### Displays

- [ ] Retina display alone: crop matches the selection pixel for pixel.
- [ ] Retina + non-Retina external display: regions on both displays crop correctly.
- [ ] External display positioned left of and above the main display.

### Upload and results

- [ ] Configured R2: link is on the clipboard, opens the image, notification click opens it too.
- [ ] Storage not configured: image is on the clipboard and saved locally; notification offers settings.
- [ ] Wrong secret key: notification explains invalid credentials; image is on the clipboard.
- [ ] Network off: retries, then fails with a network message; image is on the clipboard.
- [ ] Recent Uploads menu lists the last 10; clicking copies the link.

### Editor

Turn on **Edit After Capture** in the menu first. Check on a Retina display and, where noted, on a
non-Retina external display.

- [ ] The editor opens on the display under the mouse, in front of other apps, and in front of
      Minecraft in native full screen.
- [ ] Arrow, rectangle and redaction: draw, select, move, resize by handles, restyle, delete (⌫);
      ⇧ snaps arrows to 45° and makes squares.
- [ ] Text: click to place, type several lines, Escape commits, double-click re-edits; the text
      appears where it was typed after committing.
- [ ] Crop: draw, adjust by handles, move, Reset, ⌘Z; the uploaded image matches the crop exactly.
- [ ] The uploaded image is identical to what the editor showed (Retina and non-Retina captures).
- [ ] Text under a default-strength Pixelate area is unreadable in the uploaded image.
- [ ] Zoom: ⌘+, ⌘−, ⌘0, ⌘1, pinch; editing stays smooth on a 5K capture.
- [ ] Upload (⌘Return) gives a link; Copy (⇧⌘C) puts the image on the clipboard without uploading;
      Cancel (Escape) asks "Discard this capture?" only after changes and leaves no trace.
- [ ] Two editors open at once (capture again while one is open) finish independently.
- [ ] Edit After Capture in the menu and in Settings › General stay in sync and survive a relaunch.
- [ ] With Edit After Capture off, captures behave exactly as before.

### Settings and permissions

- [ ] Test Connection reports success with valid settings and a specific message for: wrong endpoint,
      wrong key, missing bucket, unreachable public URL.
- [ ] First launch without permissions shows onboarding; granting Screen Recording and relaunching works.
- [ ] Revoking Screen Recording while running: next capture explains and links to System Settings.
- [ ] Changing a shortcut in settings takes effect immediately.
- [ ] Launch at login toggles correctly.
