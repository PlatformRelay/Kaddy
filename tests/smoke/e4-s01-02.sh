#!/usr/bin/env bash
# REQ-E4-S01-02: clubhouse Service exposes port 8080.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

NS="gateway"
# Ensure the workload is live (idempotent; Apps use selfHeal:false).
kubectl apply -f "${SMOKE_ROOT}/deploy/gateway/namespace.yaml" >/dev/null
kubectl apply -f "${SMOKE_ROOT}/deploy/workloads/clubhouse/" >/dev/null

port="$(kubectl -n "${NS}" get svc clubhouse -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || true)"
[[ "${port}" == "8080" ]] || smoke_fail "clubhouse Service port is '${port}', expected 8080"
smoke_ok "REQ-E4-S01-02 clubhouse Service exposes port 8080"
