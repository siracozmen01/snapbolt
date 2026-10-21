# Git workflow

## Branches

- `main` is always releasable and protected: changes land only through pull requests with green CI.
- Work happens on short-lived branches named `<type>/<short-description>`:
  `feat/window-selection`, `fix/retina-crop-offset`, `docs/r2-setup-guide`.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<scope>): <summary in imperative mood, lower case, no period>

<optional body: what and why, wrapped at 72 characters>

<optional footer: Closes #12, BREAKING CHANGE: …>
```

| Type | Use for |
|---|---|
| `feat` | User-visible functionality |
| `fix` | Bug fixes |
| `refactor` | Code change without behaviour change |
| `perf` | Performance improvements |
| `test` | Adding or fixing tests only |
| `docs` | Documentation only |
| `build` | Build system, project.yml, dependencies |
| `ci` | GitHub Actions |
| `chore` | Anything else (tooling config, housekeeping) |

Scope is the module without the prefix (`upload`, `overlay`, `workflow`) or `app`, `docs`, `deps`.

Examples:

```
feat(overlay): highlight the window under the cursor
fix(upload): percent-encode spaces in object keys
docs(readme): add Cloudflare R2 setup guide
```

## Pull requests

- One logical change per PR. Aim for under ~400 changed lines (excluding tests and docs); split
  larger work into a sequence of PRs.
- The PR title follows the commit format; PRs are **squash-merged**, so the title becomes the commit
  on `main`.
- Fill in the PR template: what, why, how it was tested, screenshots or a recording for UI changes.
- Update `CHANGELOG.md` under **Unreleased** for user-visible changes.
- Update `docs/architecture.md` and add an ADR when the change affects structure or dependencies.
- CI must be green; at least one approving review once the project has more than one maintainer.

## Releases

- [Semantic Versioning](https://semver.org/): `MAJOR.MINOR.PATCH`. Before 1.0, minor versions may
  contain breaking changes.
- Tag `vX.Y.Z` on `main`; the release workflow builds the app and attaches it to a GitHub Release.
- `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); the **Unreleased**
  section is renamed to the version on release.
