# Vulcan Office branding config for ONLYOFFICE/build_tools
#
# Copied by desktop/build/build-local-windows.ps1 into
# build_tools/scripts/vulcanoffice-branding.py at build time, then referenced
# by configure.py via --branding=<path-to-parent> --branding-name=vulcanoffice.
#
# It mirrors ONLYOFFICE/build_tools/scripts/package_branding.py but replaces
# every ONLYOFFICE / Ascensio identifier with Vulcan. build_tools imports it as
# a plain module.

# -----------------------------------------------------------------------------
# NOTE: this file uses tabs for indentation ONLY where the upstream module does
# (i.e. inside function bodies). Top-level assignments are plain spaces.
# -----------------------------------------------------------------------------

import package_utils as utils

# Core identity
onlyoffice        = False   # signals build_tools NOT to run ONLYOFFICE-only code paths
company_name      = "Vulcan"
company_name_l    = company_name.lower()
publisher_name    = "Vulcan"
cert_name         = ""  # unsigned in v1

# S3 upload disabled - we publish via GitHub Releases
s3_bucket         = ""
s3_region         = ""
s3_base_url       = ""

# ------------------------- Windows-specific ---------------------------------

if utils.is_windows():
    desktop_product_name   = "Vulcan Office"
    desktop_product_name_s = desktop_product_name.replace(" ", "")   # VulcanOffice
    desktop_package_name   = "VulcanOffice-Setup"
    desktop_changes_dir    = "desktop-apps/win-linux/package/windows/update/changes"

    # File descriptors surfaced in the compiled binary's version resource
    desktop_file_description = "Vulcan Office"
    desktop_internal_name    = desktop_product_name_s
    desktop_original_filename = desktop_product_name_s + ".exe"

    # These get baked into version.rc / VS_VERSION_INFO
    desktop_company_name = company_name
    desktop_legal_copyright = "Copyright (C) 2026 Carlos Frederico Dominguez / Vulcan"

# ------------------------- macOS (not built in v1) --------------------------

if utils.is_macos():
    desktop_package_name    = "VulcanOffice"
    desktop_build_dir       = "desktop-apps/macos"
    desktop_branding_dir    = "desktop-apps/macos"
    desktop_updates_dir     = "build/update"
    desktop_changes_dir     = "VulcanOffice/update/updates/VulcanOffice/changes"
    sparkle_base_url        = ""

# ------------------------- Linux (not built in v1) --------------------------

if utils.is_linux():
    desktop_make_targets = [
        { "make": "tar", "src": "tar/*.tar*", "dst": "desktop/linux/generic/" },
        { "make": "deb", "src": "deb/*.deb",  "dst": "desktop/linux/debian/" },
    ]

# ------------------------- Doc Builder (unused, v1) -------------------------

builder_product_name = "Vulcan Office Builder"

# ------------------------- Endorsement URLs baked into installers -----------

home_url    = "https://vulcanoffice.com"
support_url = "https://vulcanoffice.com/support"
updates_url = "https://vulcanoffice.com/downloads"

# ------------------------- desktop-apps overrides consumed by qmake --------
# These flow into the .pro file via `qmake -config vulcanoffice CONFIG+=<>`
# indirectly through common.pri when --branding is used. If build_tools does
# not honor them, they must be applied by desktop/build/apply-branding.sh as
# a post-clone patch.

qmake_target = "VulcanOffice"           # replaces TARGET = DesktopEditors
app_icon_path = "./res/icons/desktopeditors.ico"  # overlay-replaced by our .ico
