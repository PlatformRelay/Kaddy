#!/usr/bin/env bash
# REQ-E12d-S01-02 — the pre-appendix spoken pitch contains 8–12 content
# slides. CoverArt-only dividers are excluded; the canonical beat order is
# checked here as well so the short path retains its narrative spine.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"
fail() { echo "FAIL: $*" >&2; exit 1; }

[ -f "${DECK}" ] || fail "slides/slides.md missing"
grep -qF '<!-- APPENDIX -->' "${DECK}" || fail "no <!-- APPENDIX --> sentinel"

MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-spoken-main.XXXXXX")"
trap 'rm -f "${MAIN}"' EXIT
sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"

# Use the same frontmatter-aware parser as the notes gate. A full-bleed
# CoverArt divider is not spoken content; every other main slide is counted.
# shellcheck source=tests/deck/lib.sh
. "${ROOT}/tests/deck/lib.sh"
content_slides="$(extract_notes "${MAIN}" | awk '$2 == "content" { count++ } END { print count + 0 }')"

[ "${content_slides}" -ge 8 ] || fail "spoken path too short: ${content_slides} < 8 content slides"
[ "${content_slides}" -le 12 ] || fail "spoken path too long: ${content_slides} > 12 content slides"

BEATS=(pitch architecture security portal-hero mulligan marshal scorecard)
mapfile -t found < <(grep -E '^beat: ' "${MAIN}" | sed 's/^beat: //') || true
i=0
for beat in "${found[@]:-}"; do
  if [ "${i}" -lt "${#BEATS[@]}" ] && [ "${beat}" = "${BEATS[${i}]}" ]; then
    i=$((i + 1))
  fi
done
[ "${i}" -eq "${#BEATS[@]}" ] || fail "beats out of order: got '${found[*]:-}'"

echo "OK: spoken path has ${content_slides} content slides and ordered beats"
