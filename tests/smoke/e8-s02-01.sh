#!/usr/bin/env bash
# REQ-E8-S02-01: capture produces prometheus/queries.json (offline fixtures).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

export SCORECARD_FIXTURES="${SCORECARD_FIXTURES:-1}"
CAPTURE="${SMOKE_ROOT}/hack/scorecard/capture.sh"
[[ -x "${CAPTURE}" ]] || smoke_fail "capture.sh missing or not executable: ${CAPTURE}"

RUN_DIR="$("${CAPTURE}" --print-run-dir)"
[[ -n "${RUN_DIR}" && -d "${RUN_DIR}" ]] || smoke_fail "capture did not report a run directory"

QUERIES="${RUN_DIR}/prometheus/queries.json"
[[ -f "${QUERIES}" ]] || smoke_fail "missing ${QUERIES}"

# Must include up, error_rate, and latency query keys (structural).
for key in up error_rate latency; do
  jq -e --arg k "${key}" 'has($k)' "${QUERIES}" >/dev/null \
    || smoke_fail "prometheus/queries.json missing key: ${key}"
done

smoke_ok "REQ-E8-S02-01 prometheus/queries.json present in ${RUN_DIR}"
