# Contributing to Snapbolt

Thanks for helping. This guide covers how to get set up and what a pull request needs to be merged.

## Before you start

- **Bugs:** open an issue with the bug report template. Include your macOS version, display setup
  and steps to reproduce.
- **Features:** open an issue first to discuss scope. Snapbolt deliberately stays small; check the
  roadmap in the [README](README.md#planned-features).
- **Security issues:** do not open a public issue; see [SECURITY.md](SECURITY.md).
- Look for issues labelled `good first issue` if you are new to the codebase.

## Setup

1. Install Xcode 16 or later and [Homebrew](https://brew.sh).
2. Clone and generate the project:

   ```bash
   make bootstrap
   make project
   open Snapbolt.xcodeproj
   ```

3. In *Signing & Capabilities*, select your personal team. A free Apple ID works. Without a stable
   signing identity macOS asks for the Screen Recording permission again after every build.
4. Run `make test` to make sure everything passes before you change anything.

## Read these first

| Document | Why |
|---|---|
| [docs/architecture.md](docs/architecture.md) | Where code goes and which module may depend on which |
| [docs/conventions/](docs/conventions/README.md) | Style, naming, file size limits, comments, errors, concurrency, tests |
| [docs/adr/](docs/adr/README.md) | Why things are the way they are |

The short version is in [AGENTS.md](AGENTS.md).

## Making a change

1. Branch from `main`: `feat/<description>`, `fix/<description>`, `docs/<description>`, …
2. Keep the change focused. Large features are split into several pull requests.
3. Add or update tests. A bug fix includes a test that fails without it.
4. Run:

   ```bash
   make format
   make lint
   make test
   ```

5. If you touched capture, the overlay, system integration or the app target, run the relevant parts
   of the [manual checklist](docs/testing.md).
6. Update `CHANGELOG.md` under **Unreleased** for user-visible changes.
7. Update `docs/architecture.md` if you changed structure; write an [ADR](docs/adr/README.md) if you
   changed a dependency rule, added a third-party package or changed a platform requirement.

## Pull requests

- Title in [Conventional Commits](https://www.conventionalcommits.org/) form:
  `feat(overlay): highlight the window under the cursor`. It becomes the squash-merge commit.
- Fill in the template, including screenshots or a short recording for anything visible.
- CI must pass: build, tests, SwiftLint (strict) and swift-format (strict).
- Be ready for review comments about structure; keeping modules small is the main thing review
  protects.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md). By participating you agree to
uphold it.

## License

By contributing you agree that your contributions are licensed under the [MIT License](LICENSE).
