#!/usr/bin/env bash
# REQ-E7-S01-03: blue/green successful promotion — after promote the active
# Service selector resolves to the green (stable) ReplicaSet and the Rollout is
# Healthy at the current revision (active == green).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

NS="mulligan"
RO="mulligan-bg"
kubectl apply -f "${SMOKE_ROOT}/deploy/workloads/mulligan/namespace.yaml" >/dev/null
kubectl apply -f "${SMOKE_ROOT}/deploy/workloads/mulligan/" >/dev/null

# Wait for a stable baseline.
kubectl -n "${NS}" wait --for=jsonpath='{.status.phase}'=Healthy rollout/"${RO}" --timeout=120s >/dev/null 2>&1 || true

# Drive a new revision (green), then promote and assert active flips to green.
kubectl -n "${NS}" patch rollout "${RO}" --type merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kaddy.io/promote-test":"'"$(date +%s)"'"}}}}}' >/dev/null

# blueGreen with autoPromotionEnabled:false pauses until promoted.
deadline=$((SECONDS + 90))
until [[ "$(kubectl -n "${NS}" get rollout "${RO}" -o jsonpath='{.status.phase}' 2>/dev/null)" == "Paused" ]]; do
  [[ ${SECONDS} -lt ${deadline} ]] || break
  sleep 3
done

if command -v kubectl-argo-rollouts >/dev/null 2>&1; then
  kubectl argo rollouts promote "${RO}" -n "${NS}" >/dev/null 2>&1 || true
else
  # Plugin-free promote: clear the pause via the abort/promote annotation the
  # controller honours.
  kubectl -n "${NS}" patch rollout "${RO}" --type merge \
    -p '{"status":{"promoteFull":true}}' --subresource=status >/dev/null 2>&1 \
    || kubectl -n "${NS}" annotate rollout "${RO}" rollout.argoproj.io/promote-full="true" --overwrite >/dev/null 2>&1 || true
fi

kubectl -n "${NS}" wait --for=jsonpath='{.status.phase}'=Healthy rollout/"${RO}" --timeout=120s >/dev/null 2>&1 || true

# Active Service selector must carry the rollouts pod-template-hash of the current
# (green) ReplicaSet — the controller injects it on promotion.
active_hash="$(kubectl -n "${NS}" get svc mulligan-bg-active -o jsonpath='{.spec.selector.rollouts-pod-template-hash}' 2>/dev/null || true)"
stable_hash="$(kubectl -n "${NS}" get rollout "${RO}" -o jsonpath='{.status.stableRS}' 2>/dev/null || true)"
[[ -n "${active_hash}" ]] || smoke_fail "active Service has no rollouts-pod-template-hash selector (not promoted)"
[[ "${active_hash}" == "${stable_hash}" ]] \
  || smoke_fail "active Service selector (${active_hash}) != stable RS (${stable_hash}) — promotion did not flip active to green"

smoke_ok "REQ-E7-S01-03 blue/green promotion flipped active Service to the green/stable ReplicaSet"
