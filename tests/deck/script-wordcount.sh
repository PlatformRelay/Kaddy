#!/usr/bin/env bash
# REQ-E12-S02-02 — the presenter notes form a coherent 5-10 minute spoken
# script (L1). Sums the words of every slide's presenter note (the LAST
# `<!-- ... -->` block per slide — same extraction rule as
# speaker-notes-coverage.sh) and asserts the total lands in 650..1500 words,
# i.e. 5-10 minutes at ~130-150 wpm.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/deck/lib.sh
. "${ROOT}/tests/deck/lib.sh"

DECK="${ROOT}/slides/slides.md"
MIN_TOTAL=650
MAX_TOTAL=1500

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

total=0
while read -r _idx _type words; do
  total=$((total + words))
done < <(extract_notes "${DECK}")

minutes_low=$((total / 150))
minutes_high=$((total / 130))
echo "spoken words: ${total} (~${minutes_low}-${minutes_high} min at 130-150 wpm)"
[ "${total}" -ge "${MIN_TOTAL}" ] || fail "script too thin: ${total} < ${MIN_TOTAL} words"
[ "${total}" -le "${MAX_TOTAL}" ] || fail "script overruns: ${total} > ${MAX_TOTAL} words"

echo "OK: script word count ${total} in [${MIN_TOTAL}, ${MAX_TOTAL}]"
