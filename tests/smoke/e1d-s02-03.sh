#!/usr/bin/env bash
# REQ-E1d-S02-03: Argo CD RBAC mapping — live argocd-rbac-cm matches the
# committed golden (operator -> role:admin, default readonly, group scopes).
# The full group-claim JWT inspection needs an interactive GitHub login and
# stays a documented operator step (docs/runbooks/github-oauth-dex.md §6).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${DIR}/../.." && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

want_default="role:readonly"
got_default="$(kubectl -n argocd get cm argocd-rbac-cm -o jsonpath='{.data.policy\.default}')"
[[ "${got_default}" == "${want_default}" ]] \
  || smoke_fail "policy.default: want ${want_default}, got '${got_default}'"
smoke_ok "policy.default is role:readonly"

live_csv="$(kubectl -n argocd get cm argocd-rbac-cm -o jsonpath='{.data.policy\.csv}')"
committed_csv="$(yq e 'select(.kind=="ConfigMap" and .metadata.name=="argocd-rbac-cm") | .data["policy.csv"]' \
  "${ROOT}/deploy/bootstrap/argocd.yaml")"
[[ "${live_csv}" == "${committed_csv}" ]] \
  || smoke_fail "live policy.csv drifts from committed deploy/bootstrap/argocd.yaml"
grep -q "g, konih, role:admin" <<<"${live_csv}" \
  || smoke_fail "operator admin mapping missing from policy.csv"
smoke_ok "policy.csv matches committed golden (operator -> role:admin)"

scopes="$(kubectl -n argocd get cm argocd-rbac-cm -o jsonpath='{.data.scopes}')"
[[ "${scopes}" == *"groups"* ]] || smoke_fail "rbac scopes do not include groups"
smoke_ok "rbac scopes include groups (team mapping ready for E10)"
