#!/usr/bin/env bash
# REQ-E12-S04-01 — the deck covers the required narrative beats, in order,
# with a per-section time budget (L1).
#
# Beat markers are slide-frontmatter keys (`beat: <name>`) on the section
# dividers. This test asserts:
#   1. all seven beats are present exactly once, in the spec's arc order:
#      pitch -> architecture -> security -> portal-hero -> mulligan ->
#      marshal -> scorecard
#   2. every section divider carries a `sectionTime: <seconds>` budget and
#      the budgets sum to 300..600 s (a 5-10 minute walkthrough).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

BEATS=(pitch architecture security portal-hero mulligan marshal scorecard)

# Ordered list of beat markers as they appear in the file.
mapfile -t found < <(grep -E '^beat: ' "${DECK}" | sed 's/^beat: //') || true

for b in "${BEATS[@]}"; do
  n=$(printf '%s\n' "${found[@]:-}" | grep -cx "${b}" || true)
  [ "${n}" -eq 1 ] || fail "beat '${b}' present ${n} times (want exactly 1)"
done

# Assert the seven required beats appear as an in-order subsequence.
i=0
for f in "${found[@]:-}"; do
  if [ "${i}" -lt "${#BEATS[@]}" ] && [ "${f}" = "${BEATS[${i}]}" ]; then
    i=$((i + 1))
  fi
done
[ "${i}" -eq "${#BEATS[@]}" ] || fail "beats out of order: got '${found[*]:-}', want subsequence '${BEATS[*]}'"

# Per-section time budget sums to a 5-10 minute walkthrough.
total=0 sections=0
while read -r secs; do
  total=$((total + secs))
  sections=$((sections + 1))
done < <(grep -E '^sectionTime: [0-9]+$' "${DECK}" | sed 's/^sectionTime: //')

[ "${sections}" -gt 0 ] || fail "no sectionTime budgets found"
echo "beats in order: ${found[*]} · sections budgeted: ${sections} · total: ${total}s"
[ "${total}" -ge 300 ] || fail "time budget too short: ${total}s < 300s"
[ "${total}" -le 600 ] || fail "time budget overruns: ${total}s > 600s"

echo "OK: narrative arc ordered (7 beats) and time budget ${total}s in [300, 600]"
