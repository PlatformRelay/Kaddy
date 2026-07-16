#!/usr/bin/env bash
# REQ-E12-S02-01 — word-by-word speaker notes on EVERY slide (L1).
#
# Rule enforced (documented):
#   * Every slide — including <CoverArt> section dividers — must end with a
#     presenter-note `<!-- ... -->` block (the LAST comment block in the slide,
#     per Slidev's presenter-note convention).
#   * Content slides need >= MIN_CONTENT_WORDS (25) — a verbatim spoken
#     paragraph, not a stub or bullet hints.
#   * CoverArt divider slides need >= MIN_COVER_WORDS (8) — a short spoken
#     transition line is expected there, not a full paragraph.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/deck/lib.sh
. "${ROOT}/tests/deck/lib.sh"

DECK="${ROOT}/slides/slides.md"
MIN_CONTENT_WORDS=25
MIN_COVER_WORDS=8

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

slides=0 noted=0 bad=0
while read -r idx type words; do
  slides=$((slides + 1))
  [ "${words}" -gt 0 ] && noted=$((noted + 1))
  min=${MIN_CONTENT_WORDS}
  [ "${type}" = "cover" ] && min=${MIN_COVER_WORDS}
  if [ "${words}" -lt "${min}" ]; then
    echo "slide ${idx} (${type}): note has ${words} words (< ${min})" >&2
    bad=$((bad + 1))
  fi
done < <(extract_notes "${DECK}")

[ "${slides}" -gt 0 ] || fail "no slides parsed from ${DECK}"
echo "slides: ${slides} · with notes: ${noted}"
[ "${noted}" -eq "${slides}" ] || fail "note-block count (${noted}) != slide count (${slides})"
[ "${bad}" -eq 0 ] || fail "${bad} slide(s) below the per-note word floor"

echo "OK: every slide (${slides}) carries a presenter note above the word floor"
