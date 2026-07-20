#!/usr/bin/env bash
# Deck quality contract: valid Slidev shell, restrained dividers, clean
# presentation chrome, semantic icons, and factual interview tone.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"
ICON="${ROOT}/slides/components/KdIcon.vue"
STYLE="${ROOT}/slides/styles/theme.css"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

[ "$(sed -n '1p' "${DECK}")" = "---" ] \
  || fail "slides.md must begin with global frontmatter (blank slide regression)"

HEADMATTER="$(mktemp "${TMPDIR:-/tmp}/deck-headmatter.XXXXXX")"
MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-quality-main.XXXXXX")"
trap 'rm -f "${HEADMATTER}" "${MAIN}"' EXIT
awk 'NR == 1 { next } /^---$/ { exit } { print }' "${DECK}" > "${HEADMATTER}"
sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"

grep -qE '^editor: false$' "${HEADMATTER}" \
  || fail "global frontmatter must disable the integrated editor"
grep -qE '^contextMenu: false$' "${HEADMATTER}" \
  || fail "global frontmatter must disable the context menu"
grep -qE '#slidev-goto-dialog[[:space:]]*\{' "${STYLE}" \
  || fail "theme must remove Slidev's persistent go-to-slide picker"
grep -A3 -E '#slidev-goto-dialog[[:space:]]*\{' "${STYLE}" | grep -qE 'display:[[:space:]]*none' \
  || fail "go-to-slide picker must be hidden with display:none"

# E12d's short spoken path may use fewer than the five available visual
# dividers; deeper cover-led sections remain valid in the appendix.
covers="$(grep -c '<CoverArt' "${MAIN}" || true)"
[ "${covers}" -ge 1 ] && [ "${covers}" -le 5 ] \
  || fail "main deck must contain 1-5 CoverArt dividers (found ${covers})"

EXPECTED_COVERS=(
  /covers/section-00-first-tee.png
  /covers/section-04-two-courses-one-blueprint.png
  /covers/section-08-gatehouse-inspection.png
  /covers/section-09-mulligans-second-chance.png
  /covers/section-12-signed-scorecard.png
)

png_dims() {
  python3 - "$1" <<'PY'
import struct
import sys

with open(sys.argv[1], "rb") as image:
    header = image.read(24)
if header[:8] != b"\x89PNG\r\n\x1a\n":
    raise SystemExit(f"not a PNG: {sys.argv[1]}")
print(*struct.unpack(">II", header[16:24]))
PY
}

for cover in "${EXPECTED_COVERS[@]}"; do
  [ "$(grep -cF "src=\"${cover}\"" "${DECK}" || true)" -eq 1 ] \
    || fail "expected cover path exactly once in deck: ${cover}"
  asset="${ROOT}/slides/public${cover}"
  [ -f "${asset}" ] || fail "referenced cover asset missing: ${asset}"
  read -r width height < <(png_dims "${asset}")
  [ "$((width * 9))" -eq "$((height * 16))" ] \
    || fail "cover asset must be 16:9, got ${width}x${height}: ${asset}"
done

# shellcheck source=tests/deck/lib.sh
. "${ROOT}/tests/deck/lib.sh"
main_slides="$(extract_notes "${MAIN}" | awk '$2 == "content" { count++ } END { print count + 0 }')"
[ "${main_slides}" -ge 8 ] && [ "${main_slides}" -le 12 ] \
  || fail "main spoken path must contain 8-12 content slides (found ${main_slides})"

if grep -Eq '✅|🧭|🚧|🚗|☸|❄' "${DECK}"; then
  fail "status and decorative emoji must use semantic icons/chips"
fi

[ -f "${ICON}" ] || fail "slides/components/KdIcon.vue missing"
grep -q 'class="kd-icon"' "${ICON}" || fail "KdIcon does not apply .kd-icon"
grep -qE '\.kd-chip([,{[:space:]]|\s*\{)' "${STYLE}" \
  || fail "theme does not define reusable .kd-chip styling"
grep -q '<KdIcon' "${DECK}" || fail "deck does not use KdIcon"
grep -q 'class="kd-chip' "${DECK}" || fail "deck does not use semantic status chips"

if grep -Eqi 'slide-ware promise|maturity flex|I did not wait to be asked' "${DECK}"; then
  fail "deck still contains defensive interview phrasing"
fi

echo "OK: deck quality — valid shell, ${main_slides} main slides, ${covers} covers, semantic icons, factual tone"
