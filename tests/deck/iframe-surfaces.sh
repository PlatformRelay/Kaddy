#!/usr/bin/env bash
# REQ-E12d-S04-02 — the deck retains five tagged platform surfaces without
# making the short spoken pitch depend on localhost iframes (L1).
#
# Asserts embed INTENT in slides/slides.md, not live endpoint reachability
# (per the spec's fallback clause). Every surface must be tagged:
#   data-surface="<name>" data-surface-mode="live|fallback|static"
# where `live` marks a public URL, and `fallback`/`static` marks an
# intentionally pitch-safe placeholder or capture. Clickable deck demo targets
# must use public GSK upstream URLs (*.lab.platformrelay.dev); local-kind
# hostnames may be documented as non-clickable implementation context.
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

if grep -Eqi '<(iframe|a)[^>]+(src|href)="[^"]*(127\.0\.0\.1|localhost|[[:alnum:].-]*\.kaddy\.local|[[:alnum:].-]*\.nip\.io|:30[0-9]{3})' "${DECK}"; then
  fail "deck demo target uses a local, kind, nip.io, or NodePort URL"
fi

# Live iframes must point at the public GSK edge, not a short/local shorthand host.
while IFS= read -r src; do
  [[ "${src}" == *".lab.platformrelay.dev"* ]] \
    || fail "live iframe src must use *.lab.platformrelay.dev (got: ${src})"
done < <(grep -oiE '<iframe[^>]+src="[^"]+"[^>]*data-surface-mode="live"|<iframe[^>]+data-surface-mode="live"[^>]*src="[^"]+"' "${DECK}" \
  | grep -oiE 'src="[^"]+"' | sed 's/^src="//;s/"$//')

echo "OK: five surfaces are tagged and demo targets use public GSK upstream URLs"
