#!/usr/bin/env bash
# REQ-E8-S02-04: capture produces loki/caddy-errors.json (offline fixtures).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

export SCORECARD_FIXTURES="${SCORECARD_FIXTURES:-1}"
CAPTURE="${SMOKE_ROOT}/hack/scorecard/capture.sh"
[[ -x "${CAPTURE}" ]] || smoke_fail "capture.sh missing or not executable: ${CAPTURE}"

RUN_DIR="$("${CAPTURE}" --print-run-dir)"
LOKI="${RUN_DIR}/loki/caddy-errors.json"
[[ -f "${LOKI}" ]] || smoke_fail "missing ${LOKI}"

jq -e '.' "${LOKI}" >/dev/null || smoke_fail "loki/caddy-errors.json is not valid JSON"

smoke_ok "REQ-E8-S02-04 loki/caddy-errors.json present in ${RUN_DIR}"
