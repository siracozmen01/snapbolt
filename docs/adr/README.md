# Architecture Decision Records

An ADR records one significant decision: the context, what was decided, and the consequences.
Write one when a change affects the module structure, adds a third-party dependency, changes a
platform requirement, or reverses an earlier decision.

## Process

1. Copy [0000-template.md](0000-template.md) to `NNNN-short-title.md` with the next free number.
2. Open a pull request with status **Proposed**. Discussion happens on the PR.
3. On merge, set status to **Accepted**.
4. ADRs are never edited after acceptance except for status. To change a decision, write a new ADR
   and set the old one to **Superseded by NNNN**.

## Index

| # | Title | Status |
|---|---|---|
| [0001](0001-native-swift-app.md) | Native Swift app | Accepted |
| [0002](0002-s3-compatible-upload.md) | S3-compatible upload with an in-house SigV4 client | Accepted |
| [0003](0003-modular-swift-package.md) | Modular local Swift package with compiler-enforced boundaries | Accepted |
| [0004](0004-xcodegen.md) | Generate the Xcode project with XcodeGen | Accepted |
| [0005](0005-macos-15-minimum.md) | macOS 15 as the minimum deployment target | Accepted |
| [0006](0006-dependency-policy-and-keyboardshortcuts.md) | Third-party dependency policy; adopt KeyboardShortcuts | Accepted |
| [0007](0007-freeze-frame-capture.md) | Freeze-frame capture before selection | Accepted |
