#!/usr/bin/env bash
# REQ-E12c-S07-01 — the Kaddy README carries a badge row (L1).
#
# Asserts README.md has a badge row with >= 3 well-formed shields.io badges for
# PlatformRelay/Kaddy, covering CI (verify workflow), deck build, license, and
# a docs/Pages badge — and that no badge points at an unpublished resource
# without a nearby caveat.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
README="${ROOT}/README.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${README}" ] || fail "README.md missing"

# Collect all shields.io / img.shields.io badge image URLs.
mapfile -t badges < <(grep -oE 'https://img\.shields\.io/[^)]+' "${README}" || true)
n=${#badges[@]}
echo "shields badges found: ${n}"
[ "${n}" -ge 3 ] || fail "expected >= 3 shields.io badges, found ${n}"

has() { grep -qE "$1" "${README}" || fail "badge row missing: $2"; }

# CI badge — the verify workflow status for PlatformRelay/Kaddy.
has 'img\.shields\.io/github/actions/workflow/status/PlatformRelay/Kaddy/verify' \
    "CI (verify.yaml workflow-status) badge for PlatformRelay/Kaddy"

# Deck-build badge — the deck workflow status.
has 'img\.shields\.io/github/actions/workflow/status/PlatformRelay/Kaddy/deck' \
    "deck-build (deck.yaml workflow-status) badge"

# License badge (any shields license badge).
has 'img\.shields\.io/[^)]*[Ll]icense' \
    "license badge"

# Docs / Pages badge (a docs or GitHub-Pages badge).
has 'img\.shields\.io/[^)]*([Dd]ocs|[Pp]ages|website)' \
    "docs/Pages badge"

# Every workflow-status badge must target the PlatformRelay/Kaddy repo.
for b in "${badges[@]}"; do
  case "${b}" in
    *actions/workflow/status/*)
      echo "${b}" | grep -q 'PlatformRelay/Kaddy' \
        || fail "workflow badge not scoped to PlatformRelay/Kaddy: ${b}" ;;
  esac
done

# Guardrail: if a badge references GitHub Pages, a caveat must be present
# (the Pages URL / license may be unpublished — the spec forbids an
# uncaveated claim).
if grep -qE 'github\.io/Kaddy' "${README}"; then
  grep -qiE 'caveat|not (yet )?published|when published|pending|live' "${README}" \
    || fail "Pages URL referenced without a caveat/status note"
fi

echo "OK: README badge row — ${n} shields badges (CI/deck/license/docs) for PlatformRelay/Kaddy, caveats honored"
