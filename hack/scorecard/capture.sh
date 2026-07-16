#!/usr/bin/env bash
# scorecard capture — produce evidence/runs/<date>/ bundle + index.html
#
# Offline (default for CI / task test:scorecard):
#   SCORECARD_FIXTURES=1 hack/scorecard/capture.sh
#   hack/scorecard/capture.sh --fixtures
#
# Live mode (deferred): omits fixtures and curls Prometheus/Alertmanager/Loki.
# --print-run-dir: run capture; print only the run directory path on stdout.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FIXTURES_DIR="${ROOT}/evidence/fixtures"
TEMPLATE="${ROOT}/hack/scorecard/template.html"
RUN_DATE="${SCORECARD_RUN_DATE:-$(date -u +%Y-%m-%d)}"
RUN_DIR="${ROOT}/evidence/runs/${RUN_DATE}"

USE_FIXTURES="${SCORECARD_FIXTURES:-0}"
PRINT_RUN_DIR=0

log() { printf '%s\n' "$*" >&2; }

usage() {
  cat >&2 <<'EOF'
Usage: hack/scorecard/capture.sh [--fixtures] [--print-run-dir] [--help]

  --fixtures       Copy/synthesize from evidence/fixtures/ (no live APIs)
  --print-run-dir  After capture, print the run directory path on stdout only
  SCORECARD_FIXTURES=1   same as --fixtures
  SCORECARD_RUN_DATE=YYYY-MM-DD   override dated run folder (default: UTC today)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fixtures) USE_FIXTURES=1; shift ;;
    --print-run-dir) PRINT_RUN_DIR=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) log "unknown arg: $1"; usage; exit 2 ;;
  esac
done

[[ -f "${TEMPLATE}" ]] || { log "missing template: ${TEMPLATE}"; exit 1; }

mkdir -p \
  "${RUN_DIR}/prometheus" \
  "${RUN_DIR}/alertmanager" \
  "${RUN_DIR}/k6" \
  "${RUN_DIR}/loki" \
  "${RUN_DIR}/rollout"

if [[ "${USE_FIXTURES}" == "1" ]]; then
  log "scorecard capture: fixture mode → ${RUN_DIR}"
  [[ -d "${FIXTURES_DIR}" ]] || { log "missing fixtures: ${FIXTURES_DIR}"; exit 1; }
  cp "${FIXTURES_DIR}/prometheus/queries.json" "${RUN_DIR}/prometheus/queries.json"
  cp "${FIXTURES_DIR}/alertmanager/alerts.json" "${RUN_DIR}/alertmanager/alerts.json"
  cp "${FIXTURES_DIR}/k6/summary.json" "${RUN_DIR}/k6/summary.json"
  cp "${FIXTURES_DIR}/loki/caddy-errors.json" "${RUN_DIR}/loki/caddy-errors.json"
  cp "${FIXTURES_DIR}/rollout/status.json" "${RUN_DIR}/rollout/status.json"
  CAPTURE_MODE="fixtures"
else
  log "scorecard capture: live mode is not implemented in this lane (use --fixtures)"
  log "hint: SCORECARD_FIXTURES=1 hack/scorecard/capture.sh"
  exit 1
fi

export SCORECARD_RUN_DATE="${RUN_DATE}"
export SCORECARD_CAPTURE_MODE="${CAPTURE_MODE}"
export SCORECARD_TEMPLATE="${TEMPLATE}"
export SCORECARD_OUT_HTML="${RUN_DIR}/index.html"
export SCORECARD_ALERTS_FILE="${RUN_DIR}/alertmanager/alerts.json"
export SCORECARD_METRICS_FILE="${RUN_DIR}/prometheus/queries.json"
export SCORECARD_K6_FILE="${RUN_DIR}/k6/summary.json"
export SCORECARD_ROLLOUT_FILE="${RUN_DIR}/rollout/status.json"

python3 <<'PY'
import html
import json
import os
from pathlib import Path

def load_compact(path: str) -> str:
    data = json.loads(Path(path).read_text(encoding="utf-8"))
    return json.dumps(data, separators=(",", ":"), ensure_ascii=False)

template = Path(os.environ["SCORECARD_TEMPLATE"]).read_text(encoding="utf-8")
repl = {
    "{{RUN_DATE}}": os.environ["SCORECARD_RUN_DATE"],
    "{{CAPTURE_MODE}}": os.environ["SCORECARD_CAPTURE_MODE"],
    "{{ALERTS_JSON}}": html.escape(load_compact(os.environ["SCORECARD_ALERTS_FILE"])),
    "{{METRICS_JSON}}": html.escape(load_compact(os.environ["SCORECARD_METRICS_FILE"])),
    "{{K6_JSON}}": html.escape(load_compact(os.environ["SCORECARD_K6_FILE"])),
    "{{ROLLOUT_JSON}}": html.escape(load_compact(os.environ["SCORECARD_ROLLOUT_FILE"])),
}
for key, value in repl.items():
    template = template.replace(key, value)
Path(os.environ["SCORECARD_OUT_HTML"]).write_text(template, encoding="utf-8")
PY

log "wrote ${RUN_DIR}/index.html"

if [[ "${PRINT_RUN_DIR}" == "1" ]]; then
  printf '%s\n' "${RUN_DIR}"
else
  log "OK: scorecard bundle at ${RUN_DIR}"
fi
