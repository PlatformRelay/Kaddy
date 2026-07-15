#!/usr/bin/env bash
# REQ-E7-S04 (in-boundary chaos) — abort a canary mid-flight → Argo Rollouts
# auto-rolls the LIVE HTTPRoute weights back to 100% stable (the "mulligan").
#
# Kicks a canary, waits for the weight to shift off 100/0, then ABORTS the
# rollout and asserts the controller snaps the HTTPRoute canary weight back to 0
# and scales the canary ReplicaSet down. Real, in-boundary, and deterministic —
# unlike the gridscale nginx chaos (hack/demo/chaos-nginx.sh, deferred).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
export KUBECONFIG="${KUBECONFIG:-${ROOT}/.state/kubeconfig}"
CTX="kind-kaddy-dev"
NS="mulligan"
k() { kubectl --context "${CTX}" -n "${NS}" "$@"; }
say() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }

kubectl --context "${CTX}" cluster-info >/dev/null 2>&1 || die "${CTX} not reachable"
kubectl --context "${CTX}" apply -f "${ROOT}/deploy/workloads/mulligan/namespace.yaml" >/dev/null
kubectl --context "${CTX}" apply -f "${ROOT}/deploy/workloads/mulligan/" >/dev/null
k wait --for=jsonpath='{.status.phase}'=Healthy rollout/mulligan --timeout=120s >/dev/null 2>&1 || true

canary_weight() { k get httproute mulligan -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="mulligan-canary")].weight}' 2>/dev/null; }

say "Kick a canary and wait for weight to shift off stable"
k patch rollout mulligan --type merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kaddy.io/abort-test":"'"$(date +%s)"'"}}}}}' >/dev/null
deadline=$((SECONDS + 90))
while [[ ${SECONDS} -lt ${deadline} ]]; do
  cw="$(canary_weight)"; [[ -n "${cw}" && "${cw}" != "0" ]] && { echo "  canary weight=${cw}"; break; }
  sleep 3
done
[[ -n "${cw:-}" && "${cw}" != "0" ]] || die "canary never took traffic — nothing to abort"

say "ABORT the rollout (the mulligan) — controller must roll weights back to stable"
if command -v kubectl-argo-rollouts >/dev/null 2>&1; then
  kubectl argo rollouts abort mulligan -n "${NS}" >/dev/null 2>&1 || true
else
  k patch rollout mulligan --type merge --subresource=status -p '{"status":{"abort":true}}' >/dev/null 2>&1 || true
fi

deadline=$((SECONDS + 90))
while [[ ${SECONDS} -lt ${deadline} ]]; do
  [[ "$(canary_weight)" == "0" ]] && break
  sleep 3
done
[[ "$(canary_weight)" == "0" ]] || die "abort did not return HTTPRoute canary weight to 0 (got $(canary_weight))"
printf '\033[1;32m✔ auto-rollback: HTTPRoute canary weight returned to 0 after abort\033[0m\n'

# Un-abort so the demo namespace is left in a clean, re-runnable state.
if command -v kubectl-argo-rollouts >/dev/null 2>&1; then
  kubectl argo rollouts retry rollout mulligan -n "${NS}" >/dev/null 2>&1 || true
else
  k patch rollout mulligan --type merge --subresource=status -p '{"status":{"abort":false}}' >/dev/null 2>&1 || true
fi
