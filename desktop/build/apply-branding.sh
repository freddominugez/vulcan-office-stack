#!/usr/bin/env bash
# apply-branding.sh - idempotent Vulcan Office overlay on top of Euro-Office/desktop-apps
#
# Usage:
#   apply-branding.sh <upstream_checkout_dir>
#
# Reruns produce byte-identical results on the target tree. Every file touched
# is printed with a "brand:" prefix so CI logs make the diff auditable.

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <path-to-desktop-apps-checkout>" >&2
    exit 2
fi

UPSTREAM="$1"
if [[ ! -d "$UPSTREAM/win-linux" ]]; then
    echo "error: '$UPSTREAM' does not look like Euro-Office/desktop-apps (no win-linux/)" >&2
    exit 2
fi

# Resolve overlay root regardless of caller's CWD.
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP="$(cd -- "$HERE/.." && pwd)"
OVERLAY="$DESKTOP/branding"

log()   { printf 'brand: %s\n' "$*"; }
copyf() {
    # copyf <src> <dst> - copy only if hash differs; stamp mtime deterministic
    local src="$1" dst="$2"
    mkdir -p "$(dirname -- "$dst")"
    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        return 0
    fi
    cp -f -- "$src" "$dst"
    touch -t 202601010000.00 -- "$dst"
    log "wrote $dst"
}
replace_placeholders() {
    # replace_placeholders <file> - substitute __BUILD_SHA__/__BUILD_DATE__/__BINARY_SHA__
    local f="$1"
    local sha="${BUILD_SHA:-unknown}"
    local date="${BUILD_DATE:-unknown}"
    local binsha="${BINARY_SHA:-pending}"
    # Deterministic sed with fixed separator that is unlikely to appear in the values.
    sed -i.bak \
        -e "s|__BUILD_SHA__|${sha}|g" \
        -e "s|__BUILD_DATE__|${date}|g" \
        -e "s|__BINARY_SHA__|${binsha}|g" \
        -- "$f"
    rm -f -- "${f}.bak"
    log "resolved placeholders in $f"
}

# 1. Windows icon (primary + upstream Euro-Office alias)
copyf "$OVERLAY/icons/vulcanoffice.ico" "$UPSTREAM/win-linux/res/icons/desktopeditors.ico"
copyf "$OVERLAY/icons/vulcanoffice.ico" "$UPSTREAM/win-linux/res/icons/desktopeditors-eo.ico"

# 2. Sidebar / About / Loading logos, both generic and -eo suffixed
for src in logo_light logo_dark loading; do
    copyf "$OVERLAY/logos/${src}.svg" "$UPSTREAM/win-linux/res/icons/${src}.svg"
done
copyf "$OVERLAY/logos/logo_light.svg"   "$UPSTREAM/win-linux/res/icons/logo-light-eo.svg"
copyf "$OVERLAY/logos/logo_dark.svg"    "$UPSTREAM/win-linux/res/icons/logo-dark-eo.svg"
copyf "$OVERLAY/logos/about-logo.svg"   "$UPSTREAM/win-linux/res/icons/app-icon-eo.svg"
copyf "$OVERLAY/logos/about-logo-white.svg" "$UPSTREAM/win-linux/res/icons/logo.svg"

# 3. About dialog HTML + legal docs, dropped next to the shell executable so the
#    Qt resource loader picks them up via qrc:/vulcanoffice/about/
mkdir -p "$UPSTREAM/win-linux/extras/vulcanoffice/about"
for f in about.html AGPL-3.0.txt NOTICE.txt THIRD-PARTY.md; do
    copyf "$OVERLAY/about/$f" "$UPSTREAM/win-linux/extras/vulcanoffice/about/$f"
done
replace_placeholders "$UPSTREAM/win-linux/extras/vulcanoffice/about/about.html"

# 4. Branding driver dot-sourced by upstream package/make.ps1
copyf "$OVERLAY/branding.ps1" "$UPSTREAM/package/branding.vulcanoffice.ps1"

# 5. Localized strings overlay for the shell (Qt Linguist .ts)
if [[ -d "$OVERLAY/strings" ]]; then
    for ts in "$OVERLAY/strings"/*.ts; do
        [[ -f "$ts" ]] || continue
        copyf "$ts" "$UPSTREAM/win-linux/langs/$(basename -- "$ts")"
    done
fi

log "overlay applied to $UPSTREAM"
