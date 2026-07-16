#!/usr/bin/env bash
# REQ-E5-S07-01 (re-pointed): access/app logs of the SERVED site (clubhouse,
# nginx-unprivileged behind the Cilium Gateway) reach Loki via Alloy — a LogQL
# query for {service="clubhouse"} returns at least one line in the ship window.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"
e5_port_forward loki 23100 3100
L="http://127.0.0.1:23100"

# Generate a fresh access-log line through the real edge (Gateway Service).
kubectl -n monitoring exec deploy/kube-prometheus-stack-grafana -c grafana -- \
  curl -sk -o /dev/null -H 'Host: clubhouse.kaddy.local' \
  https://cilium-gateway-clubhouse.gateway.svc/ 2>/dev/null || true

start="$(( $(date +%s) - 3600 ))000000000"
n=""
for _ in $(seq 1 18); do
  n="$(curl -sf --get "${L}/loki/api/v1/query_range" \
    --data-urlencode 'query={service="clubhouse"}' \
    --data-urlencode "start=${start}" \
    --data-urlencode 'limit=5' \
    | yq -p json '.data.result | length' 2>/dev/null || echo "")"
  [[ "${n}" =~ ^[1-9] ]] && break
  sleep 5
done
[[ "${n:-0}" =~ ^[1-9] ]] || smoke_fail "no {service=\"clubhouse\"} log streams in Loki"
smoke_ok "REQ-E5-S07-01 — clubhouse logs present in Loki (${n} stream(s))"
