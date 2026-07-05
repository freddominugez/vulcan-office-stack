#!/usr/bin/env bash
# check-eurooffice-updates.sh
#
# Polls Euro-Office/DocumentServer and ONLYOFFICE/onlyoffice-nextcloud upstream
# releases. If a newer tag appears than the one we've already seen AND newer
# than what is installed locally, log it and send an email. Never updates
# anything automatically.
#
# Config file: /etc/vulcan/eurooffice-check.env
# See systemd/eurooffice-check.env.example for the full variable list.

set -euo pipefail

CONFIG_FILE="${CONFIG_FILE:-/etc/vulcan/eurooffice-check.env}"
if [[ -f "${CONFIG_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}"
fi

COMPOSE_FILE="${COMPOSE_FILE:-/opt/vulcan-office-stack/docker-compose.yml}"
STATE_DIR="${STATE_DIR:-/var/lib/vulcan}"
LOG_FILE="${LOG_FILE:-/var/log/vulcan/eurooffice-updates.log}"
LOCK_FILE="${STATE_DIR}/eurooffice-check.lock"

mkdir -p "${STATE_DIR}" "$(dirname "${LOG_FILE}")"

# Single-instance lock
exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
    echo "$(date -Is) another check is running, exiting" >>"${LOG_FILE}"
    exit 0
fi

log() { echo "$(date -Is) $*" >>"${LOG_FILE}"; }

fetch_tag() {
    # $1 = owner/repo
    local repo="$1"
    curl --fail --silent --show-error --max-time 20 --retry 2 --retry-delay 5 \
        -H 'Accept: application/vnd.github+json' \
        "https://api.github.com/repos/${repo}/releases/latest" \
        | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tag_name",""))'
}

installed_editor_version() {
    # Read image reference from compose and try to derive a version. Falls back
    # to the sha256 short digest.
    if [[ ! -f "${COMPOSE_FILE}" ]]; then echo "unknown"; return; fi
    local ref
    ref=$(awk '/image: ghcr.io\/euro-office\/documentserver/ {print $2; exit}' "${COMPOSE_FILE}")
    case "${ref}" in
        *@sha256:*) echo "digest:${ref##*@sha256:}" ;;
        *:*)        echo "${ref##*:}" ;;
        *)          echo "unknown" ;;
    esac
}

installed_connector_version() {
    docker exec -u www-data vo-nextcloud php /var/www/html/occ \
        app:list --output=json 2>/dev/null \
        | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("enabled",{}).get("vulcanoffice","unknown"))' \
        2>/dev/null || echo "unknown"
}

installed_nextcloud_version() {
    docker exec -u www-data vo-nextcloud php /var/www/html/occ status 2>/dev/null \
        | awk '/versionstring:/ {print $3; exit}' \
        | cut -d. -f1 \
        || echo "unknown"
}

# For an ONLYOFFICE-connector tag, fetch appinfo/info.xml and read min/max Nextcloud
# major-version range so the alert email can flag incompatible upgrades.
connector_nc_range() {
    local tag="$1"
    curl --fail --silent --max-time 10 \
        "https://raw.githubusercontent.com/ONLYOFFICE/onlyoffice-nextcloud/${tag}/appinfo/info.xml" \
        | grep -oE 'min-version="[0-9]+" max-version="[0-9]+"' | head -1 \
        || echo ""
}

notify() {
    local subject="$1" body="$2"
    log "NOTIFY: ${subject}"
    if [[ -z "${NOTIFY_EMAIL:-}" ]]; then
        log "NOTIFY_EMAIL empty, skipping email"
        return 0
    fi
    if [[ -z "${SES_SMTP_USER:-}" || -z "${SES_SMTP_PASS:-}" ]]; then
        log "SES_SMTP_USER/PASS empty, skipping email"
        return 0
    fi
    if ! command -v swaks >/dev/null 2>&1; then
        log "swaks not installed, skipping email (install with: apt install swaks)"
        return 0
    fi
    swaks \
        --to "${NOTIFY_EMAIL}" \
        --from "${SES_FROM:-noreply@vulcanoffice.com}" \
        --server "${SES_SMTP_HOST:-email-smtp.us-east-1.amazonaws.com}" \
        --port 587 --tls \
        --auth LOGIN \
        --auth-user "${SES_SMTP_USER}" \
        --auth-password "${SES_SMTP_PASS}" \
        --header "Subject: ${subject}" \
        --body "${body}" \
        >>"${LOG_FILE}" 2>&1 || log "swaks send failed"
}

check_repo() {
    # $1 = friendly name  $2 = owner/repo  $3 = state file  $4 = installed version
    local name="$1" repo="$2" state="$3" installed="$4"
    local latest last_seen
    if ! latest=$(fetch_tag "${repo}"); then
        log "ERROR fetching ${repo} latest tag"
        return 0
    fi
    if [[ -z "${latest}" ]]; then
        log "WARN empty tag for ${repo}"
        return 0
    fi
    last_seen=""
    [[ -f "${state}" ]] && last_seen=$(cat "${state}")
    log "check ${name}: latest=${latest} last_seen=${last_seen:-none} installed=${installed}"

    if [[ "${latest}" == "${last_seen}" ]]; then
        return 0
    fi

    # New tag observed. Compare with installed and notify.
    local body compat=""
    if [[ "${repo}" == "ONLYOFFICE/onlyoffice-nextcloud" ]]; then
        local range nc
        range=$(connector_nc_range "${latest}")
        nc=$(installed_nextcloud_version)
        if [[ -n "${range}" ]]; then
            compat=$(printf '\nCompatibility: %s. Installed Nextcloud major: %s.\n' "${range}" "${nc}")
        fi
    fi
    body=$(printf 'Upstream %s released %s\nInstalled here: %s\nRepo: https://github.com/%s%s\nThis is an alert only; no automatic update was performed.\n' \
        "${name}" "${latest}" "${installed}" "${repo}" "${compat}")
    notify "[vulcan-office] ${name} ${latest} available (installed ${installed})" "${body}"
    printf '%s\n' "${latest}" >"${state}.tmp" && mv "${state}.tmp" "${state}"
}

log "=== check start ==="
check_repo "Euro-Office DocumentServer" "Euro-Office/DocumentServer" \
    "${STATE_DIR}/last-seen-eurooffice" "$(installed_editor_version)"
check_repo "ONLYOFFICE Nextcloud connector" "ONLYOFFICE/onlyoffice-nextcloud" \
    "${STATE_DIR}/last-seen-connector" "$(installed_connector_version)"
log "=== check end ==="
