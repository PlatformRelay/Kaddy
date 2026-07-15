#!/usr/bin/env bash
# REQ-E1e-S02-02: Gateway API CRDs present; cilium GatewayClass Accepted.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
kubectl get crd gateways.gateway.networking.k8s.io >/dev/null || smoke_fail "Gateway CRD missing"
kubectl get gatewayclass cilium -o json \
  | jq -e '.status.conditions[] | select(.type=="Accepted") | .status == "True"' >/dev/null \
  || smoke_fail "cilium GatewayClass not Accepted"
smoke_ok "REQ-E1e-S02-02 Gateway API CRDs + cilium GatewayClass Accepted"
