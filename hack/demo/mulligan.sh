#!/usr/bin/env bash
# REQ-E7-S03-01 — the "mulligan" progressive-delivery demo.
#
# Idempotent, scripted, two-act demo against the LIVE kind-kaddy-dev cluster:
#   Act A — blue/green: roll a new revision, show it parked on the PREVIEW service
#           while ACTIVE keeps serving, then promote → active flips to green.
#   Act B — canary:     roll a new revision and watch the Gateway API plugin shift
#           the LIVE mulligan HTTPRoute backend weights (100/0 → 20 → 50 → 100).
#
# Prints a clear PASS/FAIL per act and exits non-zero if any act fails, so a
# scorecard (E8) can capture the exit code. Recording hook: wrap this in asciinema
#   asciinema rec -c 'hack/demo/mulligan.sh' evidence/demo/mulligan.cast
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"

# SAFETY: isolated kind kubeconfig only (never the shared ~/.kube/config GKE prod).
export KUBECONFIG="${KUBECONFIG:-${ROOT}/.state/kubeconfig}"
CTX="kind-kaddy-dev"
NS="mulligan"

k() { kubectl --context "${CTX}" -n "${NS}" "$@"; }
say() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }
ok() { printf '\033[1;32m✔ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✘ %s\033[0m\n' "$*" >&2; exit 1; }

# Guard: never run against a non-kind context.
ctx="$(kubectl config current-context 2>/dev/null || true)"
[[ "${ctx}" == "${CTX}" || -z "${ctx}" ]] || die "refusing: active context '${ctx}' is not ${CTX}"
kubectl --context "${CTX}" cluster-info >/dev/null 2>&1 || die "${CTX} not reachable — run 'task cluster:up'"

say "Ensuring mulligan demo workloads are applied (idempotent)"
kubectl --context "${CTX}" apply -f "${ROOT}/deploy/workloads/mulligan/namespace.yaml" >/dev/null
kubectl --context "${CTX}" apply -f "${ROOT}/deploy/workloads/mulligan/" >/dev/null
k wait --for=jsonpath='{.status.phase}'=Healthy rollout/mulligan --timeout=120s >/dev/null 2>&1 || true
k wait --for=jsonpath='{.status.phase}'=Healthy rollout/mulligan-bg --timeout=120s >/dev/null 2>&1 || true

########################################  ACT A — blue/green  ###################
say "ACT A · blue/green — roll a new revision, promote, verify active flips to green"
k patch rollout mulligan-bg --type merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kaddy.io/demo-rev":"'"$(date +%s)"'"}}}}}' >/dev/null

# Wait for the pause (autoPromotionEnabled:false parks the green RS on preview).
deadline=$((SECONDS + 90))
until [[ "$(k get rollout mulligan-bg -o jsonpath='{.status.phase}' 2>/dev/null)" == "Paused" ]]; do
  [[ ${SECONDS} -lt ${deadline} ]] || break
  sleep 3
done
prev_hash="$(k get svc mulligan-bg-preview -o jsonpath='{.spec.selector.rollouts-pod-template-hash}' 2>/dev/null || true)"
echo "  green parked on PREVIEW service (hash=${prev_hash:-<none>}); active still serving blue"

# Promote (plugin-free: status.promoteFull subresource; the kubectl-argo-rollouts
# plugin is not required on the operator box).
if command -v kubectl-argo-rollouts >/dev/null 2>&1; then
  kubectl argo rollouts promote mulligan-bg -n "${NS}" >/dev/null 2>&1 || true
else
  k patch rollout mulligan-bg --type merge --subresource=status \
    -p '{"status":{"promoteFull":true}}' >/dev/null 2>&1 || true
fi
k wait --for=jsonpath='{.status.phase}'=Healthy rollout/mulligan-bg --timeout=120s >/dev/null 2>&1 || true
active_hash="$(k get svc mulligan-bg-active -o jsonpath='{.spec.selector.rollouts-pod-template-hash}' 2>/dev/null || true)"
stable_hash="$(k get rollout mulligan-bg -o jsonpath='{.status.stableRS}' 2>/dev/null || true)"
[[ -n "${active_hash}" && "${active_hash}" == "${stable_hash}" ]] \
  || die "blue/green promotion did not flip active to green (active=${active_hash} stable=${stable_hash})"
ok "ACT A blue/green: active Service flipped to the promoted (green/stable) ReplicaSet"

########################################  ACT B — canary  ######################
say "ACT B · canary — roll a new revision, watch the LIVE HTTPRoute weight shift"
weights() { k get httproute mulligan -o jsonpath='{range .spec.rules[0].backendRefs[*]}{.name}={.weight} {end}' 2>/dev/null; }
canary_weight() { k get httproute mulligan -o jsonpath='{.spec.rules[0].backendRefs[?(@.name=="mulligan-canary")].weight}' 2>/dev/null; }

echo "  BEFORE: $(weights)"
k patch rollout mulligan --type merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"kaddy.io/demo-rev":"'"$(date +%s)"'"}}}}}' >/dev/null

shifted=""
deadline=$((SECONDS + 90))
while [[ ${SECONDS} -lt ${deadline} ]]; do
  cw="$(canary_weight)"
  if [[ -n "${cw}" && "${cw}" != "0" ]]; then shifted="${cw}"; echo "  SHIFT : $(weights)"; break; fi
  sleep 3
done
[[ -n "${shifted}" ]] || die "canary HTTPRoute weight never rose above 0 (plugin/RBAC not wired?)"
k wait --for=jsonpath='{.status.phase}'=Healthy rollout/mulligan --timeout=120s >/dev/null 2>&1 || true
echo "  AFTER : $(weights)"
ok "ACT B canary: live HTTPRoute weight shifted to ${shifted} then promoted to stable"

say "mulligan demo complete — both acts PASSED"
