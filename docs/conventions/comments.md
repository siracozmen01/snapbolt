# Comments

Good names explain **what** code does. Comments explain **why**: intent, constraints, trade-offs and
anything surprising. A comment that restates the code is noise and is removed in review.

## Doc comments (`///`)

Required on every `public` declaration and on any non-obvious `internal` type. Written in
[DocC](https://www.swift.org/documentation/docc/) Markdown.

```swift
/// Uploads encoded images to an S3-compatible bucket.
///
/// Requests use path-style addressing (`{endpoint}/{bucket}/{key}`) so the same client works with
/// Cloudflare R2, AWS S3 and MinIO.
public final class S3Uploader: Uploading {

    /// Uploads `image` and returns its public URL.
    ///
    /// Retries network errors and HTTP 5xx responses up to two times. Client errors (4xx) are
    /// reported immediately because retrying cannot fix them.
    ///
    /// - Parameters:
    ///   - image: The encoded image and its content type.
    ///   - settings: Endpoint, bucket and credentials to use.
    /// - Returns: The object key and the public URL built from the public base URL.
    /// - Throws: ``UploadError`` describing why the upload failed.
    public func upload(_ image: EncodedImage, using settings: StorageSettings) async throws -> UploadResult
```

Rules:

- The first line is a one-sentence summary ending with a period. It says what, not how.
- Add a discussion paragraph only when there is something the signature does not tell: behaviour,
  constraints, performance, thread/actor expectations.
- Use `- Parameters:`, `- Returns:`, `- Throws:` when they add information. Skip them for trivial
  members (`/// The bucket name.` is enough for a property).
- Refer to symbols with double backticks (``` ``UploadError`` ```) so DocC links them.

## Inline comments (`//`)

Use for:

- **Why** a non-obvious choice was made:
  `// R2 rejects ACL headers, so access is controlled by the bucket's public domain instead.`
- **Workarounds**, with a link: `// Workaround for FB12345678: …`
- **Units and coordinate spaces** where a reader could get them wrong:
  `// Display pixels, origin top-left.`

Do not use for:

- Restating code: `// Increment retry count`
- Commented-out code — delete it; git remembers.
- Change logs, author names or dates — git records these.
- Separating sections inside a function — extract a function instead.

## `MARK`

`// MARK: - Title` separates groups in a file (see [file-organization.md](file-organization.md#inside-a-file)).
No `MARK` in files short enough to read on one screen.

## `TODO` and `FIXME`

Must reference a GitHub issue: `// TODO(#42): Support virtual-hosted-style URLs.`
A bare `TODO` fails SwiftLint. Do not leave `FIXME` in merged code — fix it or file an issue and
write a `TODO(#n)`.

## File headers

No file header comments (no Xcode "Created by …" blocks, no per-file license banners). The license
is in `LICENSE`; authorship is in git.
