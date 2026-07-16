#!/usr/bin/env bash
# REQ-E1d-S01-06: Dex consumes the OAuth Secret from GitOps (KSOPS render),
# not from an imperative bootstrap — proven in git AND live.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

# 1) In git: the Deployment wires env from Secret dex-github-oauth.
grep -Rq "secretKeyRef" "${ROOT}/deploy/identity/dex/" \
  || smoke_fail "deploy/identity/dex/ has no secretKeyRef wiring"
grep -Rq "dex-github-oauth" "${ROOT}/deploy/identity/dex/" \
  || smoke_fail "deploy/identity/dex/ does not reference dex-github-oauth"
smoke_ok "dex Deployment consumes Secret dex-github-oauth via secretKeyRef"

# 2) In git: the runbook documents NO imperative secret creation.
if grep -q "kubectl create secret" "${ROOT}/docs/runbooks/github-oauth-dex.md"; then
  smoke_fail "runbook still documents imperative 'kubectl create secret'"
fi
smoke_ok "runbook is free of imperative secret creation"

# 3) Live: the Secret exists AND is tracked by the identity Application
#    (i.e. it was rendered+applied by Argo CD via KSOPS, not hand-created).
tracker="$(kubectl -n identity get secret dex-github-oauth \
  -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null || true)"
[[ "${tracker}" == identity:* ]] \
  || smoke_fail "identity/dex-github-oauth missing or not ArgoCD-tracked (tracking-id='${tracker}')"
smoke_ok "live Secret identity/dex-github-oauth is rendered+tracked by the identity app (KSOPS chain proven)"

# 4) Live: same proof for the argocd-side OIDC client secret.
tracker2="$(kubectl -n argocd get secret argocd-oidc-client \
  -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null || true)"
[[ "${tracker2}" == identity:* ]] \
  || smoke_fail "argocd/argocd-oidc-client missing or not ArgoCD-tracked"
smoke_ok "live Secret argocd/argocd-oidc-client is rendered+tracked by the identity app"
