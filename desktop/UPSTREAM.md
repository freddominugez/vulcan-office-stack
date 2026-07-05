# Upstream pinning for Vulcan Office desktop v1

This file is the single source of truth for which upstream sources our Windows
installer is built from. The CI workflow (`.github/workflows/build-windows.yml`)
reads these commits and refuses to run if the checkouts drift.

## desktop-apps (shell)

- Repository: https://github.com/Euro-Office/desktop-apps
- License: AGPL-3.0
- Pinned commit: `e5f89e272861` (full: `e5f89e272861a58b395d02f09c5f3df814ab56e4`)
- Commit date: 2026-07-01
- Branch at pinning: `main`
- Rationale: no semver tag published upstream; pinned to head at time of Vulcan
  v9.3.1-vulcan.1 kickoff. Bumping this SHA requires a new contract iteration.

## DesktopEditors (engine)

- Repository: https://github.com/Euro-Office/DesktopEditors
- License: AGPL-3.0
- Pinned tag: `v9.3.1`
- Pinned commit: `5eb31cac36d0` (full: `5eb31cac36d0fb5be94d733e8606156e3d342f6f`)
- Rationale: matches the DocumentServer version running on the Vulcan Office web
  instance (`office.vulcanoffice.com`), so a document produced by the desktop
  binary is byte-identical to one produced by the web editor.

## Bumping policy

1. Pin bumps happen ONLY in a dedicated commit that touches exactly this file
   plus the CI workflow's version constants.
2. The new commit message references the upstream release notes URL.
3. A fresh D-item audit (D12 in `specs/vulcan-office-desktop-installers/`) runs
   against the new binary before publishing a new tag.
4. If the upstream deletes or force-pushes the referenced SHA, we mirror the
   tarball into the Release assets of the corresponding Vulcan tag so builds
   remain reproducible offline.
