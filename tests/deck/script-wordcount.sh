#!/usr/bin/env bash
# REQ-E12-S02-02 (ranges raised by REQ-E12c-S01-02) — the MAIN presenter notes
# form a coherent ~15-minute spoken script (L1). Sums the words of every MAIN
# slide's presenter note (the LAST `<!-- ... -->` block per slide — same
# extraction rule as speaker-notes-coverage.sh) and asserts the total lands in
# 1400..2200 words, i.e. ~11-15 minutes at ~130-150 wpm.
#
# APPENDIX exemption (E12c-S01): slides AFTER the `<!-- APPENDIX -->` sentinel
# are gate-exempt — the sum stops at the sentinel. Appendix slides still carry
# notes (speaker-notes-coverage.sh) but do not count toward this budget. If no
# sentinel is present the whole file is treated as main (backwards compatible).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/deck/lib.sh
. "${ROOT}/tests/deck/lib.sh"

DECK="${ROOT}/slides/slides.md"
MIN_TOTAL=1400
MAX_TOTAL=2200

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

# Main-only view: everything before the APPENDIX sentinel (or the whole file).
MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-main.XXXXXX")"
trap 'rm -f "${MAIN}"' EXIT
if grep -qF '<!-- APPENDIX -->' "${DECK}"; then
  sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"
else
  cp "${DECK}" "${MAIN}"
fi

total=0
while read -r _idx _type words; do
  total=$((total + words))
done < <(extract_notes "${MAIN}")

minutes_low=$((total / 150))
minutes_high=$((total / 130))
echo "main spoken words: ${total} (~${minutes_low}-${minutes_high} min at 130-150 wpm)"
[ "${total}" -ge "${MIN_TOTAL}" ] || fail "script too thin: ${total} < ${MIN_TOTAL} words"
[ "${total}" -le "${MAX_TOTAL}" ] || fail "script overruns: ${total} > ${MAX_TOTAL} words"

echo "OK: main script word count ${total} in [${MIN_TOTAL}, ${MAX_TOTAL}]"
