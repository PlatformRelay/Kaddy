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

echo "waiting for argocd-server to be Ready"
kubectl wait --for=condition=Ready pod \
  -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s \
  || smoke_fail "argocd-server pod not Ready within timeout"

phase="$(kubectl -n argocd get pod -l app.kubernetes.io/name=argocd-server \
  -o jsonpath='{.items[0].status.phase}')"
[[ "${phase}" == "Running" ]] || smoke_fail "argocd-server phase is ${phase}, expected Running"

smoke_ok "REQ-E1-S02-01 argocd-server Running"
