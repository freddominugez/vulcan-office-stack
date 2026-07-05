# Vulcan Office Windows installer GUIDs

Immutable identifiers for the Windows MSI/Inno installer. Every GUID here was
generated once with `[guid]::NewGuid()` (RFC 4122 v4) and MUST NOT be regenerated
unless a new product line is being spun up. Regenerating them breaks in-place
upgrades on every user's machine.

## AppUserModelID

`com.vulcanoffice.desktop`

Used by the Windows taskbar to group windows and pin the app to Start. Stable
across all versions.

## UpgradeCode (fixed forever)

`46396341-96D0-416A-8CB2-948502A31356`

Identifies the **Vulcan Office** product line. Every future release, every locale,
every hotfix, MUST use this same UpgradeCode so that the Windows Installer
service can detect and upgrade a previously installed copy in place.

## ProductCodes (one per locale, per version)

The list below is for the initial release **`v9.3.1-vulcan.1`**. When bumping to
a new version, generate a fresh column of ProductCodes for that version and
append (never overwrite; keep history for provenance).

### v9.3.1-vulcan.1

| Locale | ProductCode |
|---|---|
| pt-BR | `27DD6BB7-5A24-43CC-9128-4A79219958AD` |
| en-US | `1B84E676-4529-4D86-AF84-6AC95DA9A068` |
| de-DE | `AFCF8782-6807-46CE-93CB-B3D8A6A05A6D` |
| es-ES | `B6B92C27-A471-4F40-A049-7A64E7D318A8` |
| fr-FR | `02CCD2E8-AE33-4DFF-B0A9-250ABF52C711` |
| it-IT | `C136715B-D96A-4C48-A400-7CF2B3A861F4` |
| pl-PL | `04F20612-71FC-411D-83CC-D32D0BD683FF` |
| ru-RU | `895654F6-5695-49FE-8820-7039B45DFC1A` |
| uk-UA | `15BD062C-2809-4CD4-88C5-E3E5F05EEC0B` |
| ja-JP | `3A96B0E5-769B-4E87-8AE9-592F1F11AD2E` |
| zh-CN | `90ACB838-DF26-43F8-B060-ED05B274E999` |
| ko-KR | `2C1C7411-7CF3-4F30-B0DB-C85F37698142` |

## Windows LCID mapping

The upstream `package/branding.ps1` uses Microsoft LCIDs. For reference:

| Locale | LCID (decimal) | LCID (hex) |
|---|---|---|
| pt-BR | 1046 | 0x0416 |
| en-US | 1033 | 0x0409 |
| de-DE | 1031 | 0x0407 |
| es-ES | 3082 | 0x0C0A |
| fr-FR | 1036 | 0x040C |
| it-IT | 1040 | 0x0410 |
| pl-PL | 1045 | 0x0415 |
| ru-RU | 1049 | 0x0419 |
| uk-UA | 1058 | 0x0422 |
| ja-JP | 1041 | 0x0411 |
| zh-CN | 2052 | 0x0804 |
| ko-KR | 1042 | 0x0412 |

## How to reuse this file

- `branding.ps1` reads the UpgradeCode and the per-locale ProductCode table
  and injects them into the Inno Setup script via `$ProductCode` /
  `$UpgradeCode` variables.
- Never edit an already-shipped ProductCode.
- Never edit the UpgradeCode.
- Adding a new locale: generate one new v4 GUID with
  `python3 -c "import uuid; print(str(uuid.uuid4()).upper())"` and add a row.
- New version release: keep the same UpgradeCode, generate a fresh
  ProductCode column, add a new heading below the existing tables.
