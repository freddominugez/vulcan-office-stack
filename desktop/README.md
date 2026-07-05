# Vulcan Office desktop installers

Corresponding source code (AGPL-3.0) for the **Vulcan Office** Windows installer
distributed at **https://vulcanoffice.com/downloads/**.

This subtree of `vulcan-office-stack` publishes every local modification applied
on top of two AGPL-3.0 upstream projects to produce a rebranded desktop office
suite. It exists to satisfy AGPL-3.0 §5(a), §5(c), §5(d) and §6(d) for anyone
running the compiled binary.

## Upstreams

| Component | Upstream | Pinned |
|---|---|---|
| Desktop apps shell (Qt/C++) | https://github.com/Euro-Office/desktop-apps | commit `e5f89e272861` (2026-07-01) |
| Desktop editors engine | https://github.com/Euro-Office/DesktopEditors | tag `v9.3.1` (`5eb31cac36d0`) |

Both upstreams are consumed **unmodified in source form** and rebuilt with our
branding overlay. Nothing under `desktop/` here is a patched upstream file; every
modification is expressed as a) replacement asset, b) overlay script, or c) build
configuration override.

## What this subtree contains

1. **Branding overlay** in [`branding/`](./branding/) — icons, logos, About
   dialog HTML with the required legal notices, localized strings, `branding.ps1`
   variables consumed by the upstream Inno Setup build.
2. **Build scripts** in [`build/`](./build/) — `apply-branding.sh` (idempotent
   overlay onto a fresh checkout of `desktop-apps`) and the Windows build
   entrypoint.
3. **CI workflow** in [`../.github/workflows/`](../.github/workflows/) —
   `build-windows.yml` runs on `windows-latest`, clones the pinned upstream,
   applies the branding, builds `VulcanOffice-Setup-x64.exe`, and publishes to
   GitHub Releases attached to the tag.
4. **GPG release keys** in [`keys/`](./keys/) — public key for
   `Vulcan Office Releases <releases@vulcanoffice.com>` used to sign
   `sha256sums.txt` for every release.
5. **AGPL §6(d) source offer** in [`source-offer/`](./source-offer/) — the
   written offer served from the About dialog inside the binary.

## Scope of v1

- Windows x64 only (Windows 10 22H2, Windows 11 23H2).
- No Authenticode certificate — the binary is **unsigned**. First execution
  requires the user to click "More info" → "Run anyway" on SmartScreen. See
  the download page for the guided walkthrough.
- No file associations (`.docx`, `.xlsx`, `.pptx` remain bound to whatever the
  user already had).
- No auto-update. Users download new versions manually from
  `vulcanoffice.com/downloads`.
- Locales: `pt-BR` and `en-US` for shell strings. Editor engine keeps upstream
  locales.

Linux (`.deb`/`.rpm`/AppImage) and macOS (`.dmg`) are planned for v2 and are out
of scope here.

## Reproducing a release

Every tag `v<engine>-vulcan.<n>` (e.g. `v9.3.1-vulcan.1`) is reproducible from
this repository at that tag alone:

```bash
git clone --branch v9.3.1-vulcan.1 https://github.com/freddominugez/vulcan-office-stack
cd vulcan-office-stack/desktop
# On Windows with pwsh installed:
pwsh build/build-windows.ps1
```

The CI-produced `.exe` and its `sha256sum` must match locally reproduced
artifacts modulo timestamps.

## Legal

Distributed under **GNU Affero General Public License v3.0** — see the
top-level [`LICENSE`](../LICENSE). Third-party attributions in
[`branding/about/THIRD-PARTY.md`](./branding/about/THIRD-PARTY.md).

**Vulcan Office** is a modification of Euro-Office Desktop Editors, which is
itself derived from ONLYOFFICE Desktop Editors. It is NOT supplied, endorsed,
or supported by Ascensio System SIA or by the Euro-Office organization.

Modifications © 2026 Carlos Frederico Dominguez / Vulcan.
Portions © 2010–2025 Ascensio System SIA.
Portions © Euro-Office contributors.
