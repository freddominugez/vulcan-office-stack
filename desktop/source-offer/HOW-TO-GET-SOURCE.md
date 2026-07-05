# How to obtain the corresponding source (AGPL-3.0 sec. 6(d))

Vulcan Office is licensed under the **GNU Affero General Public License v3.0**.
Section 6 of that license requires that whoever distributes the binary makes
the complete corresponding source code available to the recipient. This
document is the *written offer* required by section 6(d), fulfilled by pointing
you to a publicly accessible network location.

## Where the source lives

Everything needed to rebuild your copy of Vulcan Office byte-for-byte
(modulo build timestamps) is published in a single Git repository:

**Repository:** https://github.com/freddominugez/vulcan-office-stack

Each shipped Windows installer is produced from an immutable Git tag in that
repository. The tag matches the version string shown in **Vulcan Office → About**
inside the app.

## Getting the source for a specific version

Replace `<tag>` below with the version you have installed (for example
`v9.3.1-vulcan.1`):

```bash
git clone --branch <tag> https://github.com/freddominugez/vulcan-office-stack
cd vulcan-office-stack
```

Inside the clone, the `desktop/` subtree contains everything Vulcan-specific:

- `desktop/UPSTREAM.md` records which upstream commit of
  `Euro-Office/desktop-apps` (shell) and which upstream tag of
  `Euro-Office/DesktopEditors` (engine) were used to produce this release.
- `desktop/branding/` holds every asset, string, and configuration value
  that differs from upstream.
- `desktop/build/apply-branding.sh` is the deterministic overlay script that
  applies our changes onto a fresh upstream checkout.
- `.github/workflows/build-windows.yml` is the CI pipeline that produced the
  official artifact.

## Rebuilding from source

Requirements: Windows 10/11 x64, PowerShell 5.1+ or PowerShell 7, Qt 6, Visual
Studio 2022 build tools, Inno Setup 6, and Git. Detailed instructions live in
[`desktop/README.md`](../README.md). The short version:

```bash
git clone --branch v9.3.1-vulcan.1 https://github.com/freddominugez/vulcan-office-stack
git clone https://github.com/Euro-Office/desktop-apps upstream-shell
git -C upstream-shell checkout e5f89e272861

bash vulcan-office-stack/desktop/build/apply-branding.sh upstream-shell

pwsh upstream-shell/package/make.ps1 -Branding vulcanoffice
```

The output `VulcanOffice-Setup-x64.exe` will appear under
`upstream-shell/package/build/`.

## Verifying you received unmodified source

Every release tag is annotated with the SHA-256 of the installer binary that
CI produced. To verify your local rebuild matches:

```bash
sha256sum VulcanOffice-Setup-x64.exe
```

Compare against the value in the GitHub Release notes of the same tag.

## If you cannot access GitHub

If, for any reason, `github.com/freddominugez/vulcan-office-stack` is not
accessible from your network, contact
`releases@vulcanoffice.com` and Vulcan will provide the corresponding source
via an alternate channel (mail-in USB, HTTP mirror, or similar) at no
extra charge. This obligation persists for as long as Vulcan distributes the
binary in question.

## AGPL-3.0 anchor text

> 6. Conveying Non-Source Forms.
>
> (d) Convey the object code by offering access from a designated place
> (gratis or for a charge), and offer equivalent access to the Corresponding
> Source in the same way through the same place at no further charge. You
> need not require recipients to copy the Corresponding Source along with the
> object code. If the place to copy the object code is a network server, the
> Corresponding Source may be on a different server (operated by you or a
> third party) that supports equivalent copying facilities, provided you
> maintain clear directions next to the object code saying where to find the
> Corresponding Source. Regardless of what server hosts the Corresponding
> Source, you remain obligated to ensure that it is available for as long as
> needed to satisfy these requirements.

This document IS those "clear directions".
