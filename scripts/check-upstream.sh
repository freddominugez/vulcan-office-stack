#!/usr/bin/env bash
# check-upstream.sh - report drift between the Vulcan Office fork and Euro-Office upstream.
#
# Usage:
#   scripts/check-upstream.sh <path-to-DocumentServer-checkout> [--setup]
#
#   --setup   add the missing `upstream` remotes (Euro-Office) and exit. Safe to rerun.
#
# Exit codes:
#   0  everything is level with upstream
#   3  upstream has moved ahead -- new stable tag and/or new commits (this is a
#      NOTIFICATION, not a failure; wire it to a cron/alert if you want)
#   2  usage or environment error
#
# THIS SCRIPT NEVER CHANGES YOUR CODE.
#
#   The only git operation it performs is `git fetch`, which updates remote-tracking
#   refs under .git/ and touches neither the working tree nor any local branch. It
#   does not merge, does not rebase, does not check out, does not reset. When drift
#   is found it PRINTS the merge command for a human to run -- deliberately, because
#   an automatic sync on a branch carrying the brand is how you lose the brand.
#
# WHY MERGE AND ONLY MERGE
#
#   The Vulcan rebrand is additive: it only ADDS files (web-apps/theme/vulcan-office/,
#   build/brands/vulcan-office-brand/, NOTICE.md) and edits none. So a merge from
#   upstream can essentially never conflict, and the brand survives untouched.
#
#   `git rebase` would replay our brand commit on top of upstream and rewrite its
#   hash; `git reset --hard upstream/main` would delete the brand outright. Both are
#   silent, and both are unrecoverable once pushed. Neither is ever correct here.

set -euo pipefail

UPSTREAM_ORG="https://github.com/Euro-Office"
BRAND_BRANCH="vulcanoffice"

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "usage: $0 <path-to-DocumentServer-checkout> [--setup]" >&2
    exit 2
fi

ROOT="$(cd -- "$1" 2>/dev/null && pwd)" || { echo "error: '$1' not found" >&2; exit 2; }
SETUP=false
[[ "${2:-}" == "--setup" ]] && SETUP=true

if [[ ! -f "$ROOT/build/docker-bake.hcl" ]]; then
    echo "error: '$ROOT' does not look like a DocumentServer checkout" >&2
    exit 2
fi

# The DocumentServer aggregator plus every submodule it pins.
REPOS=(
    "."  core  core-fonts  document-formats  sdkjs  sdkjs-forms  server  web-apps
    document-server-integration  document-server-package  dictionaries  document-templates
)

name_of() { [[ "$1" == "." ]] && echo "DocumentServer" || echo "$1"; }

# Resolve the remote that points at Euro-Office. Before the fork exists, `origin` is
# already Euro-Office; afterwards `origin` is our fork and `upstream` is Euro-Office.
upstream_remote() {
    local dir="$1"
    if git -C "$dir" remote get-url upstream >/dev/null 2>&1; then
        echo upstream
    elif git -C "$dir" remote get-url origin 2>/dev/null | grep -qi 'Euro-Office'; then
        echo origin
    fi
}

# ---------------------------------------------------------------------------
# --setup: add the `upstream` remote where it is missing. Additive only -- an
# existing remote is left exactly as it is.
# ---------------------------------------------------------------------------
if $SETUP; then
    for repo in "${REPOS[@]}"; do
        dir="$ROOT/$repo"
        [[ -d "$dir/.git" || -f "$dir/.git" ]] || continue
        url="$UPSTREAM_ORG/$(name_of "$repo").git"
        if git -C "$dir" remote get-url upstream >/dev/null 2>&1; then
            printf '  %-30s upstream already set\n' "$(name_of "$repo")"
        else
            git -C "$dir" remote add upstream "$url"
            printf '  %-30s upstream -> %s\n' "$(name_of "$repo")" "$url"
        fi
    done
    exit 0
fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
latest_stable_tag() {
    # Stable tags only: v1.2.3. Anything with a suffix (-rc.1, -beta.1, -tp.3, -dev.1)
    # is a prerelease and must not be proposed as an upgrade target.
    git -C "$1" tag --list --sort=-v:refname \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -1
}

drift=false

# ---------------------------------------------------------------------------
# 1. The aggregator. This is the only repo whose branch we actually merge.
# ---------------------------------------------------------------------------
ds_remote="$(upstream_remote "$ROOT")"
if [[ -z "$ds_remote" ]]; then
    echo "error: DocumentServer has no Euro-Office remote -- run with --setup" >&2
    exit 2
fi
git -C "$ROOT" fetch --quiet --tags "$ds_remote" || { echo "error: fetch failed" >&2; exit 2; }

ds_base="$ds_remote/main"
git -C "$ROOT" rev-parse --verify --quiet "$ds_base" >/dev/null || ds_base="$ds_remote/master"

ds_current="$(git -C "$ROOT" describe --tags --always)"
ds_newest="$(latest_stable_tag "$ROOT")"; [[ -z "$ds_newest" ]] && ds_newest='-'
ds_behind="$(git -C "$ROOT" rev-list --count "HEAD..$ds_base" 2>/dev/null || echo '?')"

echo
echo "DocumentServer (agregador -- o unico repo cuja branch se faz merge)"
printf '  checkout atual .......... %s\n' "$ds_current"
printf '  tag estavel no upstream . %s\n' "$ds_newest"
printf '  commits atras de %-7s %s\n' "$ds_base" "$ds_behind"

if [[ "$ds_newest" != '-' && "$ds_current" != "$ds_newest"* ]]; then
    echo "  => NOVA TAG ESTAVEL: $ds_newest"
    drift=true
fi
if [[ "$ds_behind" != "0" && "$ds_behind" != "?" ]]; then
    echo "  => upstream/main avancou $ds_behind commit(s)"
    drift=true
fi
[[ "$drift" == false ]] && echo "  => em dia"

# ---------------------------------------------------------------------------
# 2. Submodules.
#
# A submodule is NOT merged on its own -- the aggregator pins the exact commit each
# one must sit at, and that pin is what a release is made of. So "behind the
# submodule's own main" is the normal, correct state and says nothing useful.
#
# The signal that matters is whether upstream's DocumentServer has moved its PIN.
# We compare the commit we have checked out against the commit that upstream's
# default branch records for that submodule -- which is what `git ls-tree` reads.
# ---------------------------------------------------------------------------
echo
echo "Submodulos (pinados pelo agregador -- comparados contra o pin do upstream)"
printf '  %-30s %-12s %-12s %s\n' "SUBMODULO" "NOSSO PIN" "PIN UPSTREAM" "SITUACAO"
printf '  %s\n' "----------------------------------------------------------------------------"

for repo in "${REPOS[@]}"; do
    [[ "$repo" == "." ]] && continue
    dir="$ROOT/$repo"
    [[ -d "$dir/.git" || -f "$dir/.git" ]] || {
        printf '  %-30s %s\n' "$repo" "(nao inicializado -- rode: git submodule update --init)"
        continue
    }

    ours="$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo '?')"
    theirs="$(git -C "$ROOT" ls-tree "$ds_base" "$repo" 2>/dev/null | awk '{print $3}')"
    [[ -z "$theirs" ]] && theirs='?'

    if [[ "$ours" == "$theirs" ]]; then
        status="em dia"
    else
        status="PIN MUDOU no upstream"
        drift=true
    fi
    printf '  %-30s %-12s %-12s %s\n' "$repo" "${ours:0:12}" "${theirs:0:12}" "$status"
done

echo
if ! $drift; then
    echo "Nada a fazer: a fork esta nivelada com o upstream Euro-Office."
    exit 0
fi

cat <<EOF
Ha divergencia com o upstream. NADA foi aplicado -- por design.

Para sincronizar, faca MERGE (nunca rebase, nunca reset --hard) na branch de marca:

    cd <repo>
    git checkout $BRAND_BRANCH
    git fetch upstream --tags
    git merge upstream/main          # ou a tag estavel: git merge vX.Y.Z
    # resolva conflitos (nao deve haver: o rebrand so ADICIONA arquivos)
    git push origin $BRAND_BRANCH

Depois de qualquer merge, RE-APLIQUE o rebrand e confirme que ele continua limpo:

    scripts/rebrand.sh <path-to-DocumentServer-checkout>
    git -C <path> status --short     # deve mostrar apenas '??' (novos), nada modificado

EOF
exit 3
