#!/usr/bin/env bash
# REQ-E1e-S02-03: LB-IPAM pool + L2 announcement policy exist.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
kubectl get ciliumloadbalancerippool -o json | jq -e '.items | length > 0' >/dev/null \
  || smoke_fail "no CiliumLoadBalancerIPPool"
kubectl get ciliuml2announcementpolicy -o json | jq -e '.items | length > 0' >/dev/null \
  || smoke_fail "no CiliumL2AnnouncementPolicy"

# Spec S02-03 Then: a LoadBalancer Service receives an assigned address from the
# pool (assignment only — never host-curled, per the macOS note). Prove the pool
# actually assigns by creating an ephemeral LB Service and asserting an ingress IP.
NS="e1e-s0203"
cleanup() { kubectl delete ns "${NS}" --wait=false >/dev/null 2>&1 || true; }
trap cleanup EXIT
kubectl create ns "${NS}" >/dev/null 2>&1 || true
kubectl -n "${NS}" create deployment probe --image=hashicorp/http-echo:1.0.0 \
  -- -text=probe -listen=:5678 >/dev/null 2>&1 || true
kubectl -n "${NS}" expose deployment probe --type=LoadBalancer --port=80 --target-port=5678 \
  >/dev/null 2>&1 || true
lbip=""
for _ in $(seq 1 30); do
  lbip="$(kubectl -n "${NS}" get svc probe -o json 2>/dev/null \
    | jq -r '.status.loadBalancer.ingress[0].ip // empty')"
  [[ -n "${lbip}" ]] && break
  sleep 3
done
[[ -n "${lbip}" ]] || smoke_fail "LoadBalancer Service got no address from the LB-IPAM pool"
echo "LB-IPAM assigned ${lbip} to a probe Service (assignment only — NOT host-curled)"
smoke_ok "REQ-E1e-S02-03 LB-IPAM pool + L2 policy present and assigning"
