#!/usr/bin/env bash
# REQ-E8-S02-02: capture produces alertmanager/alerts.json (offline fixtures).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

export SCORECARD_FIXTURES="${SCORECARD_FIXTURES:-1}"
CAPTURE="${SMOKE_ROOT}/hack/scorecard/capture.sh"
[[ -x "${CAPTURE}" ]] || smoke_fail "capture.sh missing or not executable: ${CAPTURE}"

RUN_DIR="$("${CAPTURE}" --print-run-dir)"
ALERTS="${RUN_DIR}/alertmanager/alerts.json"
[[ -f "${ALERTS}" ]] || smoke_fail "missing ${ALERTS}"

len="$(jq 'length' "${ALERTS}")"
[[ "${len}" -ge 1 ]] || smoke_fail "alertmanager/alerts.json must be a non-empty array (got length=${len})"

smoke_ok "REQ-E8-S02-02 alertmanager/alerts.json has ${len} alert(s) in ${RUN_DIR}"
