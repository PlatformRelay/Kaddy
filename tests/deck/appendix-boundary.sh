#!/usr/bin/env bash
# REQ-E12c-S01-01 — the appendix is exempt from the main-deck time and
# word-count sums (L1).
#
# Contract asserted here (and honored by script-wordcount.sh +
# narrative-beats.sh, which split the deck at the same sentinel):
#   * slides/slides.md carries a single `<!-- APPENDIX -->` sentinel line that
#     marks the boundary between the ~15-min MAIN deck and the gate-exempt
#     appendix.
#   * The sentinel is the FIRST line of the note-region of the first appendix
#     section divider (an earlier HTML comment on that slide, so lib.sh's
#     "last comment == presenter note" rule ignores it and the appendix
#     divider still carries a real note for speaker-notes-coverage.sh).
#   * At least one real appendix content slide exists AFTER the sentinel.
#   * The two sum-gates (script-wordcount.sh, narrative-beats.sh) sum only the
#     region BEFORE the sentinel — asserted structurally here so a future edit
#     can't silently make them sum the whole file again.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

SENTINEL='<!-- APPENDIX -->'

# 1) Exactly one sentinel present.
n=$(grep -cF "${SENTINEL}" "${DECK}" || true)
[ "${n}" -eq 1 ] || fail "expected exactly one '${SENTINEL}' sentinel, found ${n}"

# 2) There is real deck content on BOTH sides of the sentinel.
line=$(grep -nF "${SENTINEL}" "${DECK}" | head -1 | cut -d: -f1)
total=$(wc -l < "${DECK}")
[ "${line}" -gt 1 ] || fail "sentinel is at the top of the file — no main deck before it"
[ "$((total - line))" -ge 10 ] || fail "no appendix content after the sentinel (only $((total - line)) lines)"

# 3) The appendix has a body after the sentinel — a section cover, a heading,
#    or a following slide divider (the sentinel is the first note-line of the
#    first appendix slide, so its OWN divider precedes it; the appendix body
#    and any further appendix slides follow).
after_body=$(tail -n "+$((line + 1))" "${DECK}" | grep -cE '^(<CoverArt|#{1,3} |---$)' || true)
[ "${after_body}" -ge 1 ] || fail "no appendix body after the sentinel (no cover/heading/divider)"

# 4) The two sum-gates must split at the sentinel (grep the source so a future
#    refactor can't drop the exemption and start summing the whole file again).
for gate in script-wordcount.sh narrative-beats.sh; do
  grep -qF 'APPENDIX' "${ROOT}/tests/deck/${gate}" \
    || fail "${gate} does not reference the APPENDIX sentinel (must sum main-only)"
done

echo "OK: APPENDIX sentinel present at line ${line}; main/appendix split honored by the sum-gates"
