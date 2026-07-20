#!/usr/bin/env bash
# REQ-E12d-S04-02 — the deck retains five tagged platform surfaces without
# making the short spoken pitch depend on localhost iframes (L1).
#
# Asserts embed INTENT in slides/slides.md, not live endpoint reachability
# (per the spec's fallback clause). Every surface must be tagged:
#   data-surface="<name>" data-surface-mode="live|fallback|static"
# where `live` marks a public URL, and `fallback`/`static` marks an
# intentionally pitch-safe placeholder or capture. Appendix demos may still
# use live frames; the spoken path must not contain localhost iframes.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

SURFACES=(backstage argocd grafana clubhouse crossplane-graph)

for s in "${SURFACES[@]}"; do
  grep -q "data-surface=\"${s}\"" "${DECK}" || fail "surface '${s}' not embedded (data-surface tag missing)"
  mode="$(grep -o "data-surface=\"${s}\" data-surface-mode=\"[a-z]*\"" "${DECK}" | head -1 | sed 's/.*data-surface-mode="//;s/"$//')"
  case "${mode}" in
    live|fallback|static) echo "surface ${s}: ${mode}" ;;
    *) fail "surface '${s}' has no live|fallback|static mode annotation" ;;
  esac
done

MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-iframe-main.XXXXXX")"
trap 'rm -f "${MAIN}"' EXIT
sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"
if grep -Eqi '<iframe[^>]+(127\.0\.0\.1|localhost)' "${MAIN}"; then
  fail "spoken path contains a localhost iframe"
fi

echo "OK: five surfaces are tagged and the spoken path is pitch-safe"
