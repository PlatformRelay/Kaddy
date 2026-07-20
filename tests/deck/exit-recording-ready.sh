#!/usr/bin/env bash
# REQ-E12-EXIT — a 5-10 minute recording can be produced from the deck.
# Composite gate: build + theme-token application + notes coverage + script
# wordcount + iframe surfaces + narrative beats must ALL pass.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# theme-tokens.sh runs right after the build: it asserts the deck's --kw-*
# style layer (graphite bg, golf-teal accent, fonts) is APPLIED, so a
# recording that builds but has drifted chrome/theme still reds this gate.
GATES=(
  slidev-build.sh
  theme-tokens.sh
  deck-quality.sh
  speaker-notes-coverage.sh
  script-wordcount.sh
  spoken-path.sh
  iframe-surfaces.sh
  surface-screenshots.sh
  narrative-beats.sh
  pitch-beats.sh
)

for g in "${GATES[@]}"; do
  echo "--- ${g}"
  bash "${DIR}/${g}" || { echo "FAIL: ${g}" >&2; exit 1; }
done

echo "OK: E12 exit gate — deck is recording-ready (build, theme-tokens, notes, wordcount, iframes, beats)"
