# Changelog

All notable changes to Snapbolt are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Optional annotation editor (arrow, rectangle, text, pixelate/blur, crop) between capture and
  upload, turned on with Edit After Capture in the menu or in Settings. Upload, copy without
  uploading, or cancel from the editor.
- Region, window and full-screen capture on a frozen screen (⌥⇧4 and ⌥⇧3, configurable), so games
  that lock the cursor no longer block selection.
- Upload to Cloudflare R2 or any S3-compatible storage, with the public link copied to the clipboard.
- Notifications for copied links and failures; the image is copied instead whenever no link can be made.
- Recent Uploads menu with the last 10 links.
- Local copies of every capture in `~/Pictures/Snapbolt` (configurable).
- Settings with a storage connection test, launch at login, and a first-launch permissions window.
- Project documentation: architecture, conventions, ADRs and the Phase 1 design.
