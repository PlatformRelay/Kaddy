#!/usr/bin/env bash
# REQ-E12-EXIT — a 5-10 minute recording can be produced from the deck.
# Composite gate: build + notes coverage + script wordcount + iframe
# surfaces + narrative beats must ALL pass.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GATES=(
  slidev-build.sh
  speaker-notes-coverage.sh
  script-wordcount.sh
  iframe-surfaces.sh
  narrative-beats.sh
)

for g in "${GATES[@]}"; do
  echo "--- ${g}"
  bash "${DIR}/${g}" || { echo "FAIL: ${g}" >&2; exit 1; }
done

echo "OK: E12 exit gate — deck is recording-ready (build, notes, wordcount, iframes, beats)"
