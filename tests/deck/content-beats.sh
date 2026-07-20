#!/usr/bin/env bash
# E12c appendix anchors retained after E12d superseded its spoken narrative.
# E12d pitch anchors live in pitch-beats.sh; this gate keeps the remaining
# appendix material checkable on the correct side of the sentinel (L1).
#
# The five-minute main arc is asserted by pitch-beats.sh. This gate continues
# to protect the retained Nix/repository appendix from accidental removal.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DECK="${ROOT}/slides/slides.md"

fail() { echo "FAIL: $*" >&2; exit 1; }
[ -f "${DECK}" ] || fail "slides/slides.md missing"

grep -qF '<!-- APPENDIX -->' "${DECK}" || fail "no <!-- APPENDIX --> sentinel (run E12c-S01 first)"

# Split the deck at the sentinel.
MAIN="$(mktemp "${TMPDIR:-/tmp}/deck-cb-main.XXXXXX")"
APPX="$(mktemp "${TMPDIR:-/tmp}/deck-cb-appx.XXXXXX")"
trap 'rm -f "${MAIN}" "${APPX}"' EXIT
sed '/<!-- APPENDIX -->/,$d' "${DECK}" > "${MAIN}"
sed -n '/<!-- APPENDIX -->/,$p' "${DECK}" > "${APPX}"

appx_has() { grep -Eq "$1" "${APPX}" || fail "APPENDIX missing anchor: $2"; }

# E12d owns all pre-sentinel narrative anchors.
bash "${ROOT}/tests/deck/pitch-beats.sh"

# --- REQ-E12c-S04-01: appendix (post-sentinel, gate-exempt) ---
appx_has 'NixOS|Nix'                              "Nix image path (appendix)"
appx_has 'ADR-0303|E14'                           "Nix refs E14/ADR-0303"
appx_has 'nix/flake\.nix'                         "landed flake.nix named"
appx_has 'image (build|builds)|build proof'       "Nix image build truth"
appx_has 'boot-to-serve.*(open|remain)|boot proof' "Nix boot-to-serve gap"
[ -f "${ROOT}/nix/flake.nix" ] || fail "nix/flake.nix must exist when appendix calls the build landed"
appx_has 'task cluster:up'                        "quickstart anchor (task cluster:up)"
appx_has 'solved-different-ways|different ways|three ways' "solved-different-ways anchor"
appx_has 'tree|repo|estate|structure'             "repo-tree anchor"
appx_has 'Caddy VM|VM'                            "Caddy VM (the literal brief) variant"

echo "OK: content-beats — all S02/S03/S04 anchors present on the correct side of the sentinel"
