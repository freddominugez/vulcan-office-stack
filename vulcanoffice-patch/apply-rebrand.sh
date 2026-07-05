#!/usr/bin/env bash
# apply-rebrand.sh
#
# Rename the ONLYOFFICE app for Nextcloud into a distinct app id so both
# forks can coexist. Only identifier strings are rewritten — upstream
# copyright, author, docs URLs and license remain intact (AGPL-3.0
# attribution requirement).
#
# Usage:
#   apply-rebrand.sh <path-to-extracted-onlyoffice-nextcloud-release>
#
# Produces (in the same parent dir):
#   ./vulcanoffice/         renamed and patched app tree
#   ./apply-rebrand.log     list of changes applied
#
# Deterministic and safe to re-run on a fresh extraction.

set -euo pipefail

SRC="${1:?usage: apply-rebrand.sh <upstream-src-dir>}"

if [[ ! -d "${SRC}" ]]; then
    echo "not a directory: ${SRC}" >&2
    exit 1
fi

if [[ ! -f "${SRC}/appinfo/info.xml" ]]; then
    echo "does not look like the ONLYOFFICE Nextcloud app: ${SRC}/appinfo/info.xml missing" >&2
    exit 1
fi

PARENT=$(cd "$(dirname "${SRC}")" && pwd)
DEST="${PARENT}/vulcanoffice"
LOG="${PARENT}/apply-rebrand.log"

FORCE=0
[[ "${2:-}" == "--force" ]] && FORCE=1

if [[ -e "${DEST}" ]]; then
    if [[ "${FORCE}" -eq 1 ]]; then
        rm -rf "${DEST}"
    else
        echo "destination already exists: ${DEST} (pass --force to overwrite)" >&2
        exit 1
    fi
fi

cp -a "${SRC}" "${DEST}"
: >"${LOG}"

log() { echo "$*" | tee -a "${LOG}"; }

# in-place sed that works on both GNU and BSD sed
sedi() {
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# 1. info.xml — app identifiers only
INFO="${DEST}/appinfo/info.xml"
log "== appinfo/info.xml =="
sedi 's|<id>onlyoffice</id>|<id>vulcanoffice</id>|' "${INFO}"
sedi 's|<namespace>Onlyoffice</namespace>|<namespace>Vulcanoffice</namespace>|' "${INFO}"
sedi 's|<name>ONLYOFFICE</name>|<name>Vulcan Office Editor</name>|' "${INFO}"
# rewrite OCA\Onlyoffice\… fully-qualified class refs in <settings>, <commands>, <background-jobs>
sedi 's|OCA\\Onlyoffice\\|OCA\\Vulcanoffice\\|g' "${INFO}"
log "  identifiers rewritten"

# 2. PHP namespaces
log "== PHP =="
COUNT=0
while IFS= read -r -d '' f; do
    if grep -q 'OCA\\Onlyoffice' "$f"; then
        sedi 's|namespace OCA\\Onlyoffice|namespace OCA\\Vulcanoffice|g' "$f"
        sedi 's|OCA\\Onlyoffice\\|OCA\\Vulcanoffice\\|g' "$f"
        COUNT=$((COUNT+1))
    fi
done < <(find "${DEST}" -type f -name '*.php' -print0)
log "  ${COUNT} PHP file(s) rewritten"

# 3. Composer autoload maps (double-escaped in PHP arrays)
log "== composer autoload =="
for f in "${DEST}/vendor/composer/autoload_psr4.php" \
         "${DEST}/vendor/composer/autoload_classmap.php" \
         "${DEST}/vendor/composer/autoload_static.php"; do
    if [[ -f "$f" ]] && grep -q 'OCA..Onlyoffice' "$f"; then
        sedi 's|OCA\\\\Onlyoffice|OCA\\\\Vulcanoffice|g' "$f"
        sedi "s|OCA\\\\\\\\Onlyoffice|OCA\\\\\\\\Vulcanoffice|g" "$f"
        log "  patched ${f##${DEST}/}"
    fi
done

# 4. l10n JS/JSON — the OC.L10N.register("onlyoffice", …) key must match app id
log "== l10n =="
COUNT=0
while IFS= read -r -d '' f; do
    if grep -q 'OC.L10N.register("onlyoffice"' "$f" 2>/dev/null \
       || grep -q '"translations"' "$f" 2>/dev/null; then
        sedi 's|OC.L10N.register("onlyoffice"|OC.L10N.register("vulcanoffice"|' "$f"
        COUNT=$((COUNT+1))
    fi
done < <(find "${DEST}/l10n" -type f \( -name '*.js' -o -name '*.json' \) -print0 2>/dev/null)
log "  ${COUNT} l10n file(s) rewritten"

# 5a. CSS class names — Nextcloud auto-generates a `.app-<id>` class on the
#     #content element. Any connector CSS selector that scopes rules under
#     that class must be renamed too, otherwise layouts (iframe height,
#     header offset) silently break on rebrand.
log "== CSS class scope =="
COUNT=0
while IFS= read -r -d '' f; do
    if grep -q "app-onlyoffice" "$f"; then
        sedi 's|app-onlyoffice|app-vulcanoffice|g' "$f"
        COUNT=$((COUNT+1))
    fi
done < <(find "${DEST}/css" "${DEST}/js" -type f \( -name '*.css' -o -name '*.js' \) -print0 2>/dev/null)
log "  ${COUNT} css/js file(s) rewritten"

# 5. Templates/lib — scoped: only rewrite the app-id in known Nextcloud API
#    calls (Util::script / Util::addScript / Util::addStyle / App::getAppPath
#    / $this->appName = / '/apps/onlyoffice/'), NOT in comments, error strings
#    or upstream URLs (onlyoffice.com etc).
log "== templates/lib (scoped) =="
COUNT=0
while IFS= read -r -d '' f; do
    if grep -qE "(Util::(script|addScript|addStyle|addHeader)|getAppPath|appName\s*=)\s*\(?['\"]onlyoffice['\"]" "$f" \
       || grep -q "/apps/onlyoffice/" "$f"; then
        # Use '#' as sed delimiter — pattern uses '|' for alternation with -E
        sedi -E "s#(Util::(script|addScript|addStyle|addHeader)\()['\"]onlyoffice['\"]#\1'vulcanoffice'#g" "$f"
        sedi -E "s#(getAppPath\()['\"]onlyoffice['\"]#\1'vulcanoffice'#g" "$f"
        sedi -E "s#(appName[[:space:]]*=[[:space:]]*)['\"]onlyoffice['\"]#\1'vulcanoffice'#g" "$f"
        sedi 's|/apps/onlyoffice/|/apps/vulcanoffice/|g' "$f"
        COUNT=$((COUNT+1))
    fi
done < <(find "${DEST}/templates" "${DEST}/lib" -type f \( -name '*.php' -o -name '*.twig' \) -print0 2>/dev/null)
log "  ${COUNT} template/lib file(s) rewritten"

# 6. Attribution assertion — refuse to publish if we accidentally erased the
#    upstream author/copyright from README/AUTHORS/appinfo.
log "== attribution assertion =="
for f in "${DEST}/README.md" "${DEST}/AUTHORS.md" "${DEST}/appinfo/info.xml"; do
    [[ -f "$f" ]] || continue
    if ! grep -qE "Ascensio System|ONLYOFFICE|onlyoffice\.com" "$f" 2>/dev/null; then
        echo "ERROR: upstream attribution missing in ${f#${DEST}/}" >&2
        echo "       aborting — inspect and adjust sed scope before retrying." >&2
        exit 2
    fi
done
log "  upstream attribution preserved (Ascensio System / ONLYOFFICE)"

log "== done =="
log "output: ${DEST}"
log "log:    ${LOG}"

echo
echo "Rebrand complete. See ${LOG} for the change summary."
echo "Deploy: copy ${DEST}/ to /var/www/html/custom_apps/vulcanoffice/"
echo "        then run: occ upgrade && occ app:enable vulcanoffice"
