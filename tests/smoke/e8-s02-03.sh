#!/usr/bin/env bash
# REQ-E8-S02-03: HTML scorecard renders alerts/metrics/k6/rollout sections.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"

export SCORECARD_FIXTURES="${SCORECARD_FIXTURES:-1}"
CAPTURE="${SMOKE_ROOT}/hack/scorecard/capture.sh"
[[ -x "${CAPTURE}" ]] || smoke_fail "capture.sh missing or not executable: ${CAPTURE}"

RUN_DIR="$("${CAPTURE}" --print-run-dir)"
HTML="${RUN_DIR}/index.html"
[[ -f "${HTML}" ]] || smoke_fail "missing ${HTML}"

# Spec Verify: HighRequestRate string present (E8 scorecard naming).
rg -q 'HighRequestRate' "${HTML}" \
  || smoke_fail "index.html must mention HighRequestRate"

for section in alerts metrics k6 rollout; do
  rg -qi "${section}" "${HTML}" \
    || smoke_fail "index.html missing section coverage: ${section}"
done

TEMPLATE="${SMOKE_ROOT}/hack/scorecard/template.html"
[[ -f "${TEMPLATE}" ]] || smoke_fail "template missing: ${TEMPLATE}"

smoke_ok "REQ-E8-S02-03 HTML scorecard present with required sections in ${RUN_DIR}"
