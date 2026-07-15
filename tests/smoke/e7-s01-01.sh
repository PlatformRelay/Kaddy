#!/usr/bin/env bash
# REQ-E7-S01-01: blue/green Rollout uses blueGreen strategy with active+preview.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

NS="mulligan"
# Ensure the demo workloads are live (idempotent; Apps use selfHeal:false).
kubectl apply -f "${SMOKE_ROOT}/deploy/workloads/mulligan/namespace.yaml" >/dev/null
kubectl apply -f "${SMOKE_ROOT}/deploy/workloads/mulligan/" >/dev/null

active="$(kubectl -n "${NS}" get rollout mulligan-bg -o jsonpath='{.spec.strategy.blueGreen.activeService}' 2>/dev/null || true)"
preview="$(kubectl -n "${NS}" get rollout mulligan-bg -o jsonpath='{.spec.strategy.blueGreen.previewService}' 2>/dev/null || true)"
[[ "${active}" == "mulligan-bg-active" ]] || smoke_fail "blueGreen activeService is '${active}', expected mulligan-bg-active"
[[ "${preview}" == "mulligan-bg-preview" ]] || smoke_fail "blueGreen previewService is '${preview}', expected mulligan-bg-preview"

# The strategy block must exist and be blueGreen (jq -e equivalent).
kubectl -n "${NS}" get rollout mulligan-bg -o jsonpath='{.spec.strategy.blueGreen}' 2>/dev/null | grep -q "mulligan-bg-active" \
  || smoke_fail "rollout mulligan-bg has no blueGreen strategy"

smoke_ok "REQ-E7-S01-01 blue/green Rollout has activeService+previewService"
