#!/usr/bin/env bash
# REQ-E12-S04-01 (ranges raised by REQ-E12c-S01-02) — the MAIN deck covers the
# required narrative beats, in order, with a per-section time budget (L1).
#
# Beat markers are slide-frontmatter keys (`beat: <name>`) on the section
# dividers. This test asserts, over the MAIN deck only (everything before the
# `<!-- APPENDIX -->` sentinel — the appendix is gate-exempt, E12c-S01):
#   1. all seven canonical beats present exactly once, in the spec's arc order:
#      pitch -> architecture -> security -> portal-hero -> mulligan ->
#      marshal -> scorecard (new, non-canonical section markers are ignored).
#   2. every MAIN section divider's `sectionTime: <seconds>` budgets sum to
#      600..1000 s (a ~11-15 minute walkthrough).
# Appendix sections MUST NOT carry `sectionTime`/canonical `beat:` markers so
# the pre-sentinel sum is unambiguous.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

# Main-only view: everything before the APPENDIX sentinel (or the whole file).
MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-beats-main.XXXXXX")"
trap 'rm -f "${MAIN}"' EXIT
if grep -qF '<!-- APPENDIX -->' "${DECK}"; then
  sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"
else
  cp "${DECK}" "${MAIN}"
fi

BEATS=(pitch architecture security portal-hero mulligan marshal scorecard)

# Ordered list of beat markers as they appear in the MAIN region.
mapfile -t found < <(grep -E '^beat: ' "${MAIN}" | sed 's/^beat: //') || true

for b in "${BEATS[@]}"; do
  n=$(printf '%s\n' "${found[@]:-}" | grep -cx "${b}" || true)
  [ "${n}" -eq 1 ] || fail "beat '${b}' present ${n} times in main (want exactly 1)"
done

# Assert the seven required beats appear as an in-order subsequence.
i=0
for f in "${found[@]:-}"; do
  if [ "${i}" -lt "${#BEATS[@]}" ] && [ "${f}" = "${BEATS[${i}]}" ]; then
    i=$((i + 1))
  fi
done
[ "${i}" -eq "${#BEATS[@]}" ] || fail "beats out of order: got '${found[*]:-}', want subsequence '${BEATS[*]}'"

# Per-section time budget over the MAIN deck sums to a ~11-15 minute walkthrough.
total=0 sections=0
while read -r secs; do
  total=$((total + secs))
  sections=$((sections + 1))
done < <(grep -E '^sectionTime: [0-9]+$' "${MAIN}" | sed 's/^sectionTime: //')

[ "${sections}" -gt 0 ] || fail "no sectionTime budgets found in main"
echo "main beats in order: ${found[*]} · sections budgeted: ${sections} · total: ${total}s"
[ "${total}" -ge 600 ] || fail "time budget too short: ${total}s < 600s"
[ "${total}" -le 1000 ] || fail "time budget overruns: ${total}s > 1000s"

echo "OK: main narrative arc ordered (7 beats) and time budget ${total}s in [600, 1000]"
