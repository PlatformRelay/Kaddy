#!/usr/bin/env bash
# REQ-E6-S01-01 — Crossplane core pods Running (GitOps-managed, ns crossplane-system).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/smoke/lib.sh
source "${DIR}/lib.sh"
smoke_require_cluster

kubectl wait --for=condition=Ready pod -l app=crossplane -n crossplane-system --timeout=300s \
  || smoke_fail "crossplane core pod not Ready"
kubectl wait --for=condition=Ready pod -l app=crossplane-rbac-manager -n crossplane-system --timeout=120s \
  || smoke_fail "crossplane rbac-manager pod not Ready"

# No pod in the namespace may be stuck non-Running/non-Succeeded (catches
# CrashLoops of function package runtime pods too).
bad="$(kubectl get pods -n crossplane-system \
  --field-selector=status.phase!=Running,status.phase!=Succeeded \
  -o name 2>/dev/null || true)"
[[ -z "${bad}" ]] || smoke_fail "non-Running pods in crossplane-system: ${bad}"

# The crossplane child Application must be GitOps-managed and healthy.
sync="$(kubectl -n argocd get application crossplane -o jsonpath='{.status.sync.status}')"
health="$(kubectl -n argocd get application crossplane -o jsonpath='{.status.health.status}')"
[[ "${sync}" == "Synced" ]] || smoke_fail "crossplane Application sync=${sync} (want Synced)"
[[ "${health}" == "Healthy" ]] || smoke_fail "crossplane Application health=${health} (want Healthy)"

smoke_ok "REQ-E6-S01-01 crossplane core Running + GitOps-managed (Synced/Healthy)"
