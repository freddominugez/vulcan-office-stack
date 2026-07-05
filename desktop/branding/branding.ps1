# Vulcan Office branding overlay for Euro-Office/desktop-apps/package/make.ps1
#
# This file is dot-sourced by the upstream package/make.ps1 when invoked with
# -Branding vulcanoffice. It overrides the default variables that drive the
# Inno Setup / Advanced Installer scripts. Every value here MUST stay in sync
# with desktop/branding/GUIDS.md and desktop/README.md.

# -- Product identity ----------------------------------------------------------

$PackageName          = "Vulcan Office"
$PackageNameShort     = "VulcanOffice"
$Publisher            = "Vulcan"
$PublisherUrl         = "https://vulcanoffice.com"
$SupportUrl           = "https://vulcanoffice.com/support"
$UpdatesUrl           = "https://vulcanoffice.com/downloads"
$BuildDir             = "build"
$DesktopDir           = "Vulcan Office"
$ExeName              = "VulcanOffice.exe"
$AppUserModelID       = "com.vulcanoffice.desktop"

# -- License fingerprint (surfaced in Add/Remove Programs) --------------------

$ProductLicense       = "GNU Affero General Public License v3.0"
$ProductComments      = "Vulcan Office is a modification of Euro-Office Desktop Editors (AGPL-3.0). Corresponding source: https://github.com/freddominugez/vulcan-office-stack"

# -- Fixed forever, do not regenerate ----------------------------------------

$UpgradeCode          = "46396341-96D0-416A-8CB2-948502A31356"

# -- Per-locale ProductCodes (v9.3.1-vulcan.1) --------------------------------
# Keyed by Microsoft LCID (decimal). Values match desktop/branding/GUIDS.md.

$ProductCodes = @{
    1046 = "27DD6BB7-5A24-43CC-9128-4A79219958AD"   # pt-BR
    1033 = "1B84E676-4529-4D86-AF84-6AC95DA9A068"   # en-US
    1031 = "AFCF8782-6807-46CE-93CB-B3D8A6A05A6D"   # de-DE
    3082 = "B6B92C27-A471-4F40-A049-7A64E7D318A8"   # es-ES
    1036 = "02CCD2E8-AE33-4DFF-B0A9-250ABF52C711"   # fr-FR
    1040 = "C136715B-D96A-4C48-A400-7CF2B3A861F4"   # it-IT
    1045 = "04F20612-71FC-411D-83CC-D32D0BD683FF"   # pl-PL
    1049 = "895654F6-5695-49FE-8820-7039B45DFC1A"   # ru-RU
    1058 = "15BD062C-2809-4CD4-88C5-E3E5F05EEC0B"   # uk-UA
    1041 = "3A96B0E5-769B-4E87-8AE9-592F1F11AD2E"   # ja-JP
    2052 = "90ACB838-DF26-43F8-B060-ED05B274E999"   # zh-CN
    1042 = "2C1C7411-7CF3-4F30-B0DB-C85F37698142"   # ko-KR
}

# Default ProductCode when a locale is not explicitly built (falls back to en-US).
$ProductCode          = $ProductCodes[1033]

# -- Advanced Installer overrides --------------------------------------------

Function BrandingAdvInstConfig {
    $ops = @(
        "DelFolder CUSTOM_PATH",
        "SetProperty Manufacturer=$Publisher",
        "SetProperty ProductName=$PackageName",
        "SetProperty ARPHELPLINK=$SupportUrl",
        "SetProperty ARPURLINFOABOUT=$PublisherUrl",
        "SetProperty ARPURLUPDATEINFO=$UpdatesUrl",
        "SetProperty FORMS=1"
    )
    foreach ($lcid in $ProductCodes.Keys) {
        $ops += "SetProductCode -langid $lcid -guid $($ProductCodes[$lcid])"
    }
    $ops += "SetProperty UpgradeCode={$UpgradeCode}"
    return $ops
}

# -- Inno Setup overrides ----------------------------------------------------
# Consumed by package/make_inno.ps1 as extra /D<key>=<value> defines.

Function BrandingInnoSetupOptions {
    return @{
        "AppName"              = $PackageName
        "AppNameShort"         = $PackageNameShort
        "AppPublisher"         = $Publisher
        "AppPublisherURL"      = $PublisherUrl
        "AppSupportURL"        = $SupportUrl
        "AppUpdatesURL"        = $UpdatesUrl
        "AppId"                = "{$UpgradeCode}"
        "DefaultDirName"       = "{autopf}\$DesktopDir"
        "DefaultGroupName"     = "Vulcan\$PackageName"
        "OutputBaseFilename"   = "VulcanOffice-Setup-x64"
        "SetupIconFile"        = "vulcanoffice.ico"
        "UninstallDisplayIcon" = "{app}\$ExeName"
        "LicenseFile"          = "AGPL-3.0.txt"
        "InfoBeforeFile"       = "NOTICE.txt"
    }
}

# -- Emit summary when dot-sourced interactively -----------------------------

if ($MyInvocation.InvocationName -eq '.') {
    Write-Host "Vulcan Office branding loaded:"
    Write-Host "  PackageName  = $PackageName"
    Write-Host "  DesktopDir   = $DesktopDir"
    Write-Host "  UpgradeCode  = $UpgradeCode"
    Write-Host "  ProductCode  = $ProductCode  (en-US default)"
    Write-Host "  Locales      = $($ProductCodes.Keys.Count)"
}
