#!/usr/bin/env bash
# REQ-CADDY-S02-03 — native in-cluster scrape of the tenant Caddy origin.
#
# Live Verify needs port-forwarded Prometheus (tests/smoke/e5-lib.sh). Offline
# this script asserts the PodMonitor is re-pointed at ns caddy-mvp with
# job="caddy" — the structural half of the scrape contract. Exit 0 offline;
# set CADDY_MVP_SCRAPE_LIVE=1 to run the PromQL assert against a live cluster.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
PODMON="${ROOT}/deploy/caddy-mvp/monitoring/prometheus/caddy-podmonitor.yaml"

fail() { echo "FAIL: $*" >&2; exit 1; }
ok()   { echo "OK: $*"; }

[[ -f "${PODMON}" ]] || fail "missing ${PODMON}"
grep -A2 'matchNames:' "${PODMON}" | grep -q 'caddy-mvp' \
  || fail "PodMonitor namespaceSelector must include caddy-mvp"
grep -q 'replacement: caddy' "${PODMON}" \
  || fail "PodMonitor must pin job=caddy"
grep -q 'podTargetLabels:' "${PODMON}" \
  || fail "PodMonitor must project podTargetLabels (track for canary SLI)"
ok "PodMonitor structural scrape wiring (ns caddy-mvp, job=caddy, podTargetLabels)"

if [[ "${CADDY_MVP_SCRAPE_LIVE:-0}" != "1" ]]; then
  echo "OK: REQ-CADDY-S02-03 offline structural (set CADDY_MVP_SCRAPE_LIVE=1 for PromQL)"
  exit 0
fi

# shellcheck source=/dev/null
source "${DIR}/lib.sh"
# shellcheck source=/dev/null
source "${DIR}/e5-lib.sh"
smoke_require_cluster
e5_prom_up
val="$(e5_prom_query 'up{job="caddy",namespace="caddy-mvp"}')"
[[ "${val}" == "1" ]] || fail "expected up{job=caddy,namespace=caddy-mvp}==1, got '${val}'"
ok "live PromQL up{job=caddy,namespace=caddy-mvp}==1"
