#!/usr/bin/env bash
# Operator showcase screenshots must live under slides/public/surfaces/ (committed;
# stuff/ is gitignored) and be referenced from the deck + root README.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"
README="${ROOT}/README.md"
SURFACES="${ROOT}/slides/public/surfaces"

fail() { echo "FAIL: $*" >&2; exit 1; }

ASSETS=(
  argocd-app-of-apps.png
  backstage-portal.png
  grafana-alerting.png
  marketplace-listing.png
)

[ -d "${SURFACES}" ] || fail "slides/public/surfaces/ missing"
[ -f "${DECK}" ] || fail "slides/slides.md missing"
[ -f "${README}" ] || fail "README.md missing"

for a in "${ASSETS[@]}"; do
  [ -f "${SURFACES}/${a}" ] || fail "missing screenshot asset: slides/public/surfaces/${a}"
  grep -Fq "/surfaces/${a}" "${DECK}" \
    || fail "deck must reference /surfaces/${a}"
  grep -Fq "slides/public/surfaces/${a}" "${README}" \
    || fail "README must reference slides/public/surfaces/${a} (GitHub-relative)"
done

echo "OK: surface screenshots present and wired into deck + README"
