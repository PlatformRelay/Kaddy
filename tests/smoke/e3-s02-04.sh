#!/usr/bin/env bash
# REQ-E3-S02-04: Grafana Alloy DaemonSet desired == ready (scheduled on all nodes).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
NS=monitoring

echo "=== waiting for Alloy DaemonSet rollout ==="
# Resolve the DaemonSet name by label, then roll out (kubectl rollout status by
# label selector is not supported for a specific ds).
ds=""
for _ in $(seq 1 30); do
  ds="$(kubectl -n "${NS}" get ds -l app.kubernetes.io/name=alloy \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  [[ -n "${ds}" ]] && break
  sleep 5
done
[[ -n "${ds}" ]] || smoke_fail "Alloy DaemonSet not found in ns ${NS}"

kubectl -n "${NS}" rollout status "ds/${ds}" --timeout=180s \
  || smoke_fail "Alloy DaemonSet ${ds} did not roll out"

desired="$(kubectl -n "${NS}" get ds "${ds}" -o jsonpath='{.status.desiredNumberScheduled}')"
ready="$(kubectl -n "${NS}" get ds "${ds}" -o jsonpath='{.status.numberReady}')"
[[ "${desired}" -ge 1 && "${desired}" == "${ready}" ]] \
  || smoke_fail "Alloy ds desired(${desired}) != ready(${ready})"
smoke_ok "REQ-E3-S02-04 (Alloy ds ${ds}: desired==ready==${ready})"
