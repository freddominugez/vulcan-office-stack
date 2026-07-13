#!/usr/bin/env bash
# rebrand.sh - idempotent Vulcan Office overlay on top of Euro-Office/DocumentServer
#
# Usage:
#   scripts/rebrand.sh <path-to-DocumentServer-checkout>
#
# Reruns produce byte-identical results on the target tree. Every file touched is
# printed with a "brand:" prefix so CI logs make the diff auditable.
#
# WHAT THIS DOES
#   Almost everything is additive -- it creates two directories and one file, all of
#   which this script owns and regenerates from scratch on every run:
#
#     web-apps/theme/vulcan-office/          (web-apps ships a first-class theme system)
#     build/brands/vulcan-office-brand/      (the bake "brand-icons" overlay context)
#     NOTICE.md                              (AGPL attribution + list of modifications)
#
#   Plus EXACTLY ONE edit to an upstream file, and it is unavoidable:
#
#     web-apps/.docker/web-apps.bake.Dockerfile
#       Upstream HARDCODES `THEME=euro-office` on the build-pipeline line. The theme
#       system is otherwise fully wired -- so without this patch our theme directory is
#       built and then ignored, and the image comes out looking like Euro-Office while
#       every other check (healthcheck, image size, install paths) passes. That failure
#       is silent, which is why it is worth one line of patch. We turn the hardcoded
#       value into an ARG so the brand can select it.
#
#   Nothing in core/sdkjs/sdkjs-forms/core-fonts/document-formats is touched at all.
#
# WHY IT LOOKS LIKE THIS
#   Upstream supports downstream brands natively, so no mass sed is needed:
#     - web-apps/build/theme.config.mjs resolves every brand token as
#       env var > theme/<THEME>/meta/config.json > ONLYOFFICE default.
#     - server / example / packages overlay an optional "brand-icons" image.
#     - document-server-package/Makefile declares every brand var with `?=`.
#   Renaming internal identifiers (e.g. the postMessage wire value
#   `msg.Referer == "onlyoffice"`) would break the build and the integration
#   contract, so this script never rewrites code -- only brand data and assets.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <path-to-DocumentServer-checkout>" >&2
    exit 2
fi

UPSTREAM="$(cd -- "$1" 2>/dev/null && pwd)" || { echo "error: '$1' not found" >&2; exit 2; }

for required in build/docker-bake.hcl web-apps/theme/euro-office server/branding; do
    if [[ ! -e "$UPSTREAM/$required" ]]; then
        echo "error: '$UPSTREAM' does not look like Euro-Office/DocumentServer (no $required)" >&2
        echo "hint: run 'git submodule update --init' first" >&2
        exit 2
    fi
done

# Resolve our own tree regardless of the caller's CWD.
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd -- "$HERE/.." && pwd)"
BRAND="$ROOT/brand"
LOGOS="$ROOT/branding"

# shellcheck source=../brand/brand.env
source "$BRAND/brand.env"

log()   { printf 'brand: %s\n' "$*"; }
copyf() {
    # copyf <src> <dst> - copy, then stamp a fixed mtime so reruns are byte-identical
    local src="$1" dst="$2"
    mkdir -p -- "$(dirname -- "$dst")"
    cp -f -- "$src" "$dst"
    touch -t 202601010000.00 -- "$dst"
}

THEME_SRC="$UPSTREAM/web-apps/theme/euro-office"
THEME_DST="$UPSTREAM/web-apps/theme/$THEME"
BRAND_DST="$UPSTREAM/build/brands/vulcan-office-brand"
OVERLAY="$BRAND_DST/overlay"

# ---------------------------------------------------------------------------
# 1. web-apps theme
#
# Derived from the upstream euro-office theme rather than vendored, so that an
# upstream change to the theme's LESS or its doc-type icons flows in on the next
# run instead of silently going stale. Only the brand-bearing files are replaced.
# ---------------------------------------------------------------------------
rm -rf -- "$THEME_DST"
cp -a -- "$THEME_SRC" "$THEME_DST"
log "derived web-apps/theme/$THEME from upstream euro-office theme"

# The upstream theme ships its logos under eo_* names, referenced from its own
# theme.less and meta/config.json. We replace both of those, so drop the stale files.
rm -f -- "$THEME_DST/assets/img/header/eo_logo_light.svg" \
         "$THEME_DST/assets/img/header/eo_logo_dark.svg"

# Brand assets. branding/ is the single source for Vulcan artwork -- the same SVGs
# the old bind-mount deployment used, so the editor looks identical to production.
#   *_light = the logo is light (white, #fff) and sits on a dark header
#   *_dark  = the logo is dark (#222) and sits on a light header
copyf "$LOGOS/header-logo_s.svg" "$THEME_DST/assets/img/header/vulcan_logo_light.svg"
copyf "$LOGOS/dark-logo_s.svg"   "$THEME_DST/assets/img/header/vulcan_logo_dark.svg"
copyf "$LOGOS/header-logo_s.svg" "$THEME_DST/assets/img/header/header-logo_s.svg"
copyf "$LOGOS/dark-logo_s.svg"   "$THEME_DST/assets/img/header/dark-logo_s.svg"
copyf "$LOGOS/about-logo_s.svg"  "$THEME_DST/assets/img/about/logo.svg"
copyf "$LOGOS/embed-logo.svg"    "$THEME_DST/assets/img/embed/logo.svg"
log "wrote brand logos into web-apps/theme/$THEME/assets/img/"

copyf "$BRAND/web-apps-theme/assets/less/theme.less" "$THEME_DST/assets/less/theme.less"
log "wrote web-apps/theme/$THEME/assets/less/theme.less"

# meta/config.json. Generated from brand.env so the values cannot drift apart.
# `attribution` carries the AGPL 7(b) credit to Ascensio and Euro-Office; `publisher_url`
# is what the About dialog renders as a clickable link (AGPL 13).
cat > "$THEME_DST/meta/config.json" <<JSON
{
  "company_name": "$COMPANY_NAME",
  "publisher_name": "$PUBLISHER_NAME",
  "publisher_url": "$PUBLISHER_URL",
  "publisher_address": "$PUBLISHER_ADDRESS",
  "publisher_phone": "$PUBLISHER_PHONE",
  "sales_email": "$SALES_EMAIL",
  "support_email": "$SUPPORT_EMAIL",
  "support_url": "$SUPPORT_URL",
  "help_url": "$HELP_URL",
  "app_title": "$APP_TITLE_TEXT",
  "attribution": "$ATTRIBUTION",
  "mobile_logo_light": "vulcan_logo_light.svg",
  "mobile_logo_dark": "vulcan_logo_dark.svg",
  "about_logo_light": "logo.svg",
  "about_logo_dark": "logo.svg",
  "forms_logo_light": "vulcan_logo_dark.svg",
  "forms_logo_dark": "vulcan_logo_light.svg"
}
JSON
touch -t 202601010000.00 -- "$THEME_DST/meta/config.json"
log "wrote web-apps/theme/$THEME/meta/config.json"

# ---------------------------------------------------------------------------
# 1b. Make the web-apps theme selectable.
#
# The one upstream file we edit. Upstream hardcodes `THEME=euro-office` in the build
# step, so the theme directory written above would be built and then never selected.
# Idempotent: the sed only matches the unpatched form, and rerunning is a no-op.
# ---------------------------------------------------------------------------
WA_DOCKERFILE="$UPSTREAM/web-apps/.docker/web-apps.bake.Dockerfile"
# Guard on `ARG THEME`, NOT on `THEME=euro-office`: the line we insert is
# `ARG THEME=euro-office` (that is its default), so guarding on the literal
# `THEME=euro-office` matches our own patch and re-applies it on every run --
# stacking a fresh ARG line each time. Caught by the run-it-twice test.
if ! grep -q 'ARG THEME' "$WA_DOCKERFILE"; then
    sed -i \
        -e 's|^\( *\)ARG BUILD_ROOT=/package|\1ARG BUILD_ROOT=/package\n\1ARG THEME=euro-office|' \
        -e 's|THEME=euro-office \\|THEME=${THEME} \\|' \
        "$WA_DOCKERFILE"

    # Second half of the same patch: substitute the brand tokens in the deployed HTML.
    #
    # This works around an UPSTREAM REGRESSION in v9.3.2. build/scripts/deploy-html.js
    # -- which its own comment describes as replacing "grunt's copy:indexhtml +
    # replace:indexhtml steps" -- only ever substitutes @@SRC_ROOT@@. It dropped the
    # {{TOKEN}} replacement that `replace:indexhtml` used to do, so every editor ships
    # with a literal `{{APP_TITLE_TEXT}}` in its <title> and a broken splash logo.
    #
    # It is genuinely a regression, not our doing: the 9.3.1 image running in
    # production has a substituted title, and a stock 9.3.2 build does not.
    #
    # These are exactly the three tokens theme/README.md documents for editor HTML.
    cat >> "$WA_DOCKERFILE" <<'DOCKERFILE'

    # --- Vulcan Office: work around upstream v9.3.2 dropping {{TOKEN}} substitution
    # in the deployed HTML (build/scripts/deploy-html.js only handles @@SRC_ROOT@@).
    ARG APP_TITLE_TEXT=ONLYOFFICE
    ARG LOADER_LOGO=dark-logo_s.svg
    ARG LOADER_LOGO_DARK=header-logo_s.svg

    RUN find ${BUILD_ROOT} -name '*.html' -exec sed -i \
            -e "s|{{APP_TITLE_TEXT}}|${APP_TITLE_TEXT}|g" \
            -e "s|{{LOADER_LOGO_DARK}}|${LOADER_LOGO_DARK}|g" \
            -e "s|{{LOADER_LOGO}}|${LOADER_LOGO}|g" {} + && \
        ! grep -rq '{{[A-Z_]*}}' ${BUILD_ROOT} --include='*.html'
DOCKERFILE
    log "patched web-apps/.docker/web-apps.bake.Dockerfile (THEME arg + HTML token fix)"
else
    log "web-apps.bake.Dockerfile already patched"
fi

# ---------------------------------------------------------------------------
# 2. brand-icons overlay (server + example + package)
# ---------------------------------------------------------------------------
rm -rf -- "$BRAND_DST"
mkdir -p -- "$BRAND_DST"
copyf "$BRAND/brand-server.hcl" "$BRAND_DST/brand-server.hcl"

# The DocumentServer info/welcome pages served by the server itself. Derived from
# upstream with brand substitutions so an upstream edit to the markup flows through.
brand_html() {
    # brand_html <src> <dst> - rewrite brand strings, leave everything else alone
    local src="$1" dst="$2"
    mkdir -p -- "$(dirname -- "$dst")"
    sed -e "s|https://github\.com/euro-office|$PUBLISHER_URL|g" \
        -e "s|Euro-Office|$COMPANY_NAME|g" \
        -e "s|Euro Office|$COMPANY_NAME|g" \
        "$src" > "$dst"
    touch -t 202601010000.00 -- "$dst"
}

SRV_SRC="$UPSTREAM/server/branding"
SRV_DST="$OVERLAY/server/branding"
brand_html "$SRV_SRC/info/index.html"    "$SRV_DST/info/index.html"
brand_html "$SRV_SRC/welcome/index.html" "$SRV_DST/welcome/index.html"
log "wrote overlay/server/branding/{info,welcome}/index.html"

copyf "$LOGOS/dark-logo_s.svg" "$SRV_DST/info/img/logo.svg"
copyf "$LOGOS/favicon.ico"     "$SRV_DST/info/img/favicon.ico"
copyf "$LOGOS/favicon.ico"     "$SRV_DST/welcome/img/favicon.ico"
log "wrote overlay/server/branding/**/img/"

# The AdminPanel is a separate React app inside server/; its assets are overlaid
# before `npm run build` runs (server.bake.Dockerfile:36 precedes :54).
ADMIN_DST="$OVERLAY/server/AdminPanel/client"
copyf "$LOGOS/dark-logo_s.svg"   "$ADMIN_DST/src/assets/logo.svg"
copyf "$LOGOS/dark-logo_s.svg"   "$ADMIN_DST/src/assets/AppLogo.svg"
copyf "$LOGOS/dark-logo_s.svg"   "$ADMIN_DST/src/assets/AppMenuLogo.svg"
copyf "$LOGOS/header-logo_s.svg" "$ADMIN_DST/src/assets/dark-logo_s.svg"
copyf "$LOGOS/favicon.ico"       "$ADMIN_DST/public/images/favicon.ico"
log "wrote overlay/server/AdminPanel/client/ assets"

# The example / welcome app (document-server-integration). Its Dockerfile already
# rewrites the literal "Euro-Office" to $COMPANY_NAME at build time, so only the
# artwork needs overlaying here.
EX_DST="$OVERLAY/document-server-integration/web/documentserver-example/nodejs/public/images"
copyf "$LOGOS/dark-logo_s.svg" "$EX_DST/logo.svg"
copyf "$LOGOS/dark-logo_s.svg" "$EX_DST/mobile-logo.svg"
copyf "$LOGOS/favicon.ico"     "$EX_DST/favicon.ico"
log "wrote overlay/document-server-integration/ images"

# ---------------------------------------------------------------------------
# 3. NOTICE.md
#
# AGPL requires the upstream copyright notices to survive. We add ours alongside
# Ascensio's and Euro-Office's -- never in place of them.
# ---------------------------------------------------------------------------
cat > "$UPSTREAM/NOTICE.md" <<'NOTICE'
# NOTICE

**Vulcan Office Document Server** is a rebranded build of
[Euro-Office DocumentServer](https://github.com/Euro-Office/DocumentServer), which is
itself a fork of [ONLYOFFICE Document Server](https://github.com/ONLYOFFICE/DocumentServer),
originally developed by **Ascensio System SIA**.

## Licence

GNU Affero General Public License v3.0 (AGPL-3.0). See `LICENSE` for the full text.

Copyright (c) Ascensio System SIA — original ONLYOFFICE Document Server
Copyright (c) Euro-Office contributors — Euro-Office DocumentServer
Copyright (c) 2026 Vulcan — Vulcan Office modifications

The copyright notices of the upstream authors are preserved throughout the source
tree and must not be removed.

## Corresponding source (AGPL-3.0 section 13)

The complete corresponding source code of the Vulcan Office service, including every
modification listed below, is published at:

**<https://github.com/freddominugez/vulcan-office-stack>**

## Modifications made by Vulcan

All Vulcan changes are **additive** — no upstream source file is edited in place, and
no internal identifier is renamed. They are applied deterministically by
`scripts/rebrand.sh` in the repository above:

1. **`web-apps/theme/vulcan-office/`** — a new theme (upstream `web-apps` supports
   downstream themes natively). Supplies Vulcan logos, brand colours, and a
   `meta/config.json` carrying the brand strings and the AGPL attribution.
2. **`build/brands/vulcan-office-brand/`** — the `brand-icons` overlay consumed by the
   upstream bake: Vulcan artwork for the server info/welcome pages, the AdminPanel,
   and the example app.
3. **Build-time brand variables** — `COMPANY_NAME`, `PRODUCT_NAME`, `PUBLISHER_*`,
   `THEME`, exported from `brand/brand.env`. Upstream already reads all of these.

No change is made to `core`, `sdkjs`, `sdkjs-forms`, `core-fonts` or `document-formats`.

## Attribution

Per AGPL-3.0 section 7(b), the credit to Ascensio System SIA and to Euro-Office is
preserved and displayed in the editor's **About** dialog. It must not be removed.

ONLYOFFICE is a trademark of Ascensio System SIA. Vulcan Office is not affiliated with,
endorsed by, or sponsored by Ascensio System SIA.
NOTICE
touch -t 202601010000.00 -- "$UPSTREAM/NOTICE.md"
log "wrote NOTICE.md"

echo
log "done. rebrand is idempotent -- rerunning yields an identical tree."
log "build with: COMPANY_NAME='$COMPANY_NAME' THEME='$THEME' \\"
log "            docker buildx bake -f ./docker-bake.hcl \\"
log "                               -f ./brands/vulcan-office-brand/brand-server.hcl \\"
log "                               brand-icons packages standalone"
