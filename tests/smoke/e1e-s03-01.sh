#!/usr/bin/env bash
# REQ-E1e-S03-01: cert-manager Ready + kaddy-local-ca ClusterIssuer Ready.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=180s
kubectl get clusterissuer kaddy-local-ca -o json \
  | jq -e '.status.conditions[] | select(.type=="Ready") | .status == "True"' >/dev/null \
  || smoke_fail "kaddy-local-ca ClusterIssuer not Ready"
smoke_ok "REQ-E1e-S03-01 cert-manager + kaddy-local-ca Ready"
