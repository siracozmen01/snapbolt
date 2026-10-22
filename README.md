# Snapbolt

**Screenshot → your own bucket → link on your clipboard.** A free, open-source ShareX-style capture
tool for macOS that uploads to Cloudflare R2 or any S3-compatible storage.

> **Status: Phase 1 in testing.** Capture and upload are implemented and being tested on real
> hardware; there is no release yet. Build from source to try it, or follow the repository for the
> first release.

## Why

- **Your storage, your links.** Upload to your own R2, S3 or MinIO bucket. No accounts, no third-party
  image hosts.
- **Works in games.** Snapbolt freezes the screen first and lets you select on the frozen image, so
  games that lock the cursor (like Minecraft) no longer trap the crosshair in the middle of the
  screen.
- **Captures the moment you pressed the key**, not the moment you finished selecting.
- **Native and light.** Swift, ScreenCaptureKit, a menu bar icon and nothing else running.
- **No telemetry.** Snapbolt sends nothing anywhere except the uploads you make to your own bucket.

## Planned features

| Phase | Features |
|---|---|
| 1 | Region, window and full-screen capture · upload to S3-compatible storage · link to clipboard · notifications · recent uploads · local copies |
| 2 | Editor: arrows, boxes, text, pixelate/blur, crop before uploading (Edit After Capture) |
| 3 | Screen recording to MP4 (and GIF), uploaded the same way |

## Requirements

- macOS 15 Sequoia or later
- A Cloudflare R2 bucket (or any S3-compatible storage) for uploads — optional; without it Snapbolt
  copies the image to the clipboard and saves it locally.

## Installing

Once a version is released:

1. Download `Snapbolt-vX.Y.Z.zip` from [Releases](https://github.com/siracozmen01/snapbolt/releases)
   and move `Snapbolt.app` to Applications.
2. Snapbolt is not notarized yet, so the first launch is blocked by Gatekeeper. Open it once with
   **right-click → Open**, or allow it under **System Settings → Privacy & Security → Open Anyway**.
3. Grant **Screen Recording** when Snapbolt asks, then quit and reopen it.
4. Press **⌥⇧4** to capture a region or window, **⌥⇧3** for the display under the cursor. Both can be
   changed in **Settings → Shortcuts**.

## Setting up Cloudflare R2

1. In the Cloudflare dashboard, open **R2 Object Storage** and **create a bucket**
   (e.g. `screenshots`).
2. Make the bucket publicly readable, in the bucket's **Settings**:
   - **Custom Domains** → connect a domain you manage in Cloudflare (e.g. `i.example.com`), or
   - **Public Development URL** → enable the `r2.dev` URL. It is rate-limited and meant for testing.
3. Back in **R2 Object Storage**, open **Manage API tokens** → **Create API token**:
   - Permissions: **Object Read & Write**
   - Specify bucket: only the bucket from step 1
4. Copy the **Access Key ID**, the **Secret Access Key** and the S3 endpoint
   (`https://<ACCOUNT_ID>.r2.cloudflarestorage.com`). The secret is shown only once.
5. In Snapbolt **Settings → Storage**, fill in:

   | Field | Value |
   |---|---|
   | Endpoint | `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` |
   | Region | `auto` |
   | Bucket | `screenshots` |
   | Access Key ID / Secret Access Key | from step 4 |
   | Public base URL | `https://i.example.com` or your `https://pub-….r2.dev` URL |

6. Click **Test Connection**.

Coming from ShareX? These are the same values you entered in ShareX's *Amazon S3* destination.

The Secret Access Key is stored in the macOS Keychain, never in a plain file.

## Building from source

Requires Xcode 26 or later and [Homebrew](https://brew.sh).

```bash
git clone https://github.com/siracozmen01/snapbolt.git
cd snapbolt
make bootstrap   # installs XcodeGen and SwiftLint
make project     # generates Snapbolt.xcodeproj
open Snapbolt.xcodeproj
```

To keep the Screen Recording permission across rebuilds, sign with your own Apple Development
certificate (a free Apple ID is enough) by creating `Config/Signing.local.xcconfig`:

```
DEVELOPMENT_TEAM = ABCDE12345
CODE_SIGN_IDENTITY = Apple Development
```

The file is git-ignored. Without it the app is ad-hoc signed and macOS asks for the permission again
after every build.

## Contributing

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) first; the architecture and code
rules are in [docs/](docs/architecture.md).

## License

[MIT](LICENSE)
