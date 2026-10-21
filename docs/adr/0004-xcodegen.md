# 0004. Generate the Xcode project with XcodeGen

- **Status:** Accepted
- **Date:** 2026-10-21

## Context

A macOS app needs an Xcode app target for its bundle, Info.plist, entitlements, assets and code
signing. The `.xcodeproj/project.pbxproj` file is machine-written, hard to review and a constant
source of merge conflicts in open-source projects.

## Decision

Describe the app target in `project.yml` and generate the project with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`make project`). `*.xcodeproj` is in `.gitignore`.
The project references the local `SnapboltKit` package.

## Alternatives considered

- **Commit the `.xcodeproj`** — unreviewable diffs and merge conflicts.
- **Tuist** — more powerful than needed for a single app target; heavier to learn and install.
- **SwiftPM only, with a script that assembles the `.app`** — avoids Xcode project files entirely,
  but asset catalogs, signing and debugging the app bundle are more awkward for contributors used
  to Xcode.

## Consequences

- Contributors run `make bootstrap` once and `make project` after pulling changes to `project.yml`.
- Project settings are reviewed as readable YAML.
- XcodeGen is a build-time tool only; it is not shipped with the app.
