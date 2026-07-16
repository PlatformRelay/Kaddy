#!/usr/bin/env bash
# Validate a scorecard run bundle schema (REQ-E8-EXIT).
#
# Usage:
#   hack/scorecard/validate.sh [evidence/runs/YYYY-MM-DD]
#   If omitted, validates the newest directory under evidence/runs/.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNS="${ROOT}/evidence/runs"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "OK: $*"; }

resolve_run() {
  if [[ $# -ge 1 && -n "${1:-}" ]]; then
    local arg="$1"
    if [[ "${arg}" = /* ]]; then
      printf '%s\n' "${arg}"
    else
      printf '%s\n' "${ROOT}/${arg}"
    fi
    return
  fi
  [[ -d "${RUNS}" ]] || fail "no runs directory: ${RUNS}"
  local latest
  latest="$(find "${RUNS}" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)"
  [[ -n "${latest}" ]] || fail "no run bundles under ${RUNS}"
  printf '%s\n' "${latest}"
}

RUN_DIR="$(resolve_run "${1:-}")"
[[ -d "${RUN_DIR}" ]] || fail "run dir missing: ${RUN_DIR}"

need_file() {
  [[ -f "$1" ]] || fail "missing required file: $1"
}

need_file "${RUN_DIR}/index.html"
need_file "${RUN_DIR}/prometheus/queries.json"
need_file "${RUN_DIR}/alertmanager/alerts.json"
need_file "${RUN_DIR}/k6/summary.json"
need_file "${RUN_DIR}/loki/caddy-errors.json"

command -v jq >/dev/null 2>&1 || fail "jq required for schema checks"

jq -e 'type == "object"' "${RUN_DIR}/prometheus/queries.json" >/dev/null \
  || fail "prometheus/queries.json must be a JSON object"
for key in up error_rate latency; do
  jq -e --arg k "${key}" 'has($k)' "${RUN_DIR}/prometheus/queries.json" >/dev/null \
    || fail "prometheus/queries.json missing key: ${key}"
done

jq -e 'type == "array" and length >= 1' "${RUN_DIR}/alertmanager/alerts.json" >/dev/null \
  || fail "alertmanager/alerts.json must be a non-empty array"

jq -e 'type == "object"' "${RUN_DIR}/k6/summary.json" >/dev/null \
  || fail "k6/summary.json must be a JSON object"
jq -e 'type == "object"' "${RUN_DIR}/loki/caddy-errors.json" >/dev/null \
  || fail "loki/caddy-errors.json must be a JSON object"

rg -q 'HighRequestRate' "${RUN_DIR}/index.html" \
  || fail "index.html must mention HighRequestRate"
for section in alerts metrics k6 rollout; do
  rg -qi "${section}" "${RUN_DIR}/index.html" \
    || fail "index.html missing section: ${section}"
done

ok "scorecard bundle schema valid: ${RUN_DIR}"
