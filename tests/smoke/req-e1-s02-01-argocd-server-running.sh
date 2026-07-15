#!/usr/bin/env bash
# REQ-E1-S02-01: ArgoCD server Running.
# Bootstraps ArgoCD via the idempotent `task bootstrap:argocd` (pinned upstream
# install + the deploy/bootstrap/argocd.yaml overlay) and asserts the
# argocd-server pod in the argocd namespace becomes Ready.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

OVERLAY="${SMOKE_ROOT}/deploy/bootstrap/argocd.yaml"
[[ -f "${OVERLAY}" ]] || smoke_fail "bootstrap overlay missing: ${OVERLAY}"

# Idempotent bring-up (reused across re-runs). The task pins the upstream
# ArgoCD version and applies the overlay.
( cd "${SMOKE_ROOT}" && task bootstrap:argocd ) || smoke_fail "task bootstrap:argocd failed"

echo "waiting for argocd-server rollout + Ready"
# Wait on the Deployment first so we don't race a rollout (old pods terminating).
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s \
  || smoke_fail "argocd-server deployment did not roll out"
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s \
  || smoke_fail "argocd-server pod not Ready within timeout"

# At least one argocd-server pod must be in phase Running (ignore any old pod
# left in Succeeded/Failed during a rollout).
running="$(kubectl -n argocd get pod -l app.kubernetes.io/name=argocd-server \
  -o json | jq '[.items[] | select(.status.phase=="Running")] | length')"
[[ "${running:-0}" -ge 1 ]] || smoke_fail "no argocd-server pod in phase Running"

smoke_ok "REQ-E1-S02-01 argocd-server Running"
