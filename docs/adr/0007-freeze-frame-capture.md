# 0007. Freeze-frame capture before selection

- **Status:** Accepted
- **Date:** 2026-10-21

## Context

The built-in macOS region capture selects on the live screen with the live cursor. Games that lock
the cursor to the window centre (Minecraft and most first-person games) leave the crosshair stuck,
so a region cannot be selected. Live selection also captures the screen as it is when the selection
ends, not when the user pressed the shortcut.

## Decision

On a capture shortcut, first capture every display with ScreenCaptureKit, then show an overlay that
displays the frozen images and let the user select on them. Snapbolt activates itself when the
overlay appears, so the game loses focus and releases the cursor. The final image is a crop of the
frozen frame; no second capture is taken. Window selection also crops the frozen frame.

## Alternatives considered

- **Live selection, then capture** (`screencapture -i` style) — the cursor-lock problem remains.
- **Capture the window alone with `SCScreenshotManager` after selecting it** — gives a clean window
  without overlapping content, but the image no longer matches what the user saw and the moment is
  lost. May be offered later as an option.

## Consequences

- Works with games that lock the cursor, and captures the exact moment of the key press.
- Memory: one full-resolution image per display is held while the overlay is open (tens of MB on a
  5K display), released immediately after.
- The overlay must cover native full-screen spaces, which needs specific panel settings.
