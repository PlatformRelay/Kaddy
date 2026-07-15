#!/usr/bin/env bash
# REQ-E7-S02-03 (+ REQ-E7-S02-01 / REQ-E2-S02-03): the canary Rollout carries the
# `track` label AND the Gateway API plugin mutates the LIVE HTTPRoute backend
# weights during a rollout. This is the load-bearing weight-mutation proof.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

NS="mulligan"
RO="mulligan"
HR="mulligan"
kubectl apply -f "${SMOKE_ROOT}/deploy/workloads/mulligan/namespace.yaml" >/dev/null
kubectl apply -f "${SMOKE_ROOT}/deploy/workloads/mulligan/" >/dev/null

weights() {
  kubectl -n "${NS}" get httproute "${HR}" \
    -o jsonpath='{range .spec.rules[0].backendRefs[*]}{.name}={.weight} {end}' 2>/dev/null
}
canary_weight() {
  kubectl -n "${NS}" get httproute "${HR}" \
    -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="mulligan-canary")].weight}' 2>/dev/null
}

# 0) track label present on the pod template (Prometheus dimension).
tracklbl="$(kubectl -n "${NS}" get rollout "${RO}" -o jsonpath='{.spec.template.metadata.labels.track}' 2>/dev/null || true)"
[[ "${tracklbl}" == "stable" ]] || smoke_fail "canary Rollout pod template missing track=stable (got '${tracklbl}')"

# 1) wait for steady state (canary weight 0).
kubectl -n "${NS}" wait --for=jsonpath='{.status.phase}'=Healthy rollout/"${RO}" --timeout=120s >/dev/null 2>&1 || true
before="$(weights)"
echo "BEFORE weights: ${before}"

# 2) trigger a new revision → canary steps begin (first step setWeight 20, pause).
kubectl -n "${NS}" patch rollout "${RO}" --type merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kaddy.io/weight-test":"'"$(date +%s)"'"}}}}}' >/dev/null

# 3) assert the LIVE HTTPRoute canary weight rises above 0 within the window.
shifted=""
deadline=$((SECONDS + 90))
while [[ ${SECONDS} -lt ${deadline} ]]; do
  cw="$(canary_weight)"
  if [[ -n "${cw}" && "${cw}" != "0" ]]; then
    shifted="${cw}"
    break
  fi
  sleep 3
done
after="$(weights)"
echo "AFTER  weights: ${after}"
[[ -n "${shifted}" ]] \
  || smoke_fail "HTTPRoute canary weight never rose above 0 during rollout (plugin/RBAC not wired?)"
echo "canary weight shifted to ${shifted} on the live HTTPRoute"

# 4) let it converge back to a clean state for idempotency (auto-promotes via steps).
kubectl -n "${NS}" wait --for=jsonpath='{.status.phase}'=Healthy rollout/"${RO}" --timeout=120s >/dev/null 2>&1 || true

smoke_ok "REQ-E7-S02-03 track label present + live HTTPRoute weight mutated during canary"
