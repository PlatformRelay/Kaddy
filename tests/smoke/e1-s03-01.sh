#!/usr/bin/env bash
# REQ-E1-S03-01: Cluster baseline Ready.
# Asserts the E1e substrate invariants E1 depends on: all nodes Ready, a default
# StorageClass exists, Cilium pods are Ready, and a CiliumLoadBalancerIPPool is
# present. E1e provisions all of these, so this script is an assertion gate for
# E1 (it goes green the moment the substrate is up — there is no separate impl).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

# 1) All nodes Ready.
not_ready="$(kubectl get nodes -o json \
  | jq '[.items[].status.conditions[] | select(.type=="Ready" and .status!="True")] | length')"
[[ "${not_ready}" == "0" ]] || smoke_fail "one or more nodes not Ready"
echo "all nodes Ready"

# 2) A default StorageClass exists (annotation is the source of truth).
default_sc="$(kubectl get storageclass -o json \
  | jq -r '.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true") | .metadata.name' \
  | head -1)"
[[ -n "${default_sc}" ]] || smoke_fail "no default StorageClass found"
echo "default StorageClass: ${default_sc}"

# 3) Cilium pods Ready (agent + operator in kube-system).
kubectl wait --for=condition=Ready pod -l k8s-app=cilium -n kube-system --timeout=120s >/dev/null \
  || smoke_fail "cilium agent pods not Ready"
echo "cilium pods Ready"

# 4) A CiliumLoadBalancerIPPool is present (LB-IPAM configured).
pool_count="$(kubectl get ciliumloadbalancerippool -o json 2>/dev/null | jq '.items | length')"
[[ "${pool_count:-0}" -ge 1 ]] || smoke_fail "no CiliumLoadBalancerIPPool present"
echo "CiliumLoadBalancerIPPool present (${pool_count})"

smoke_ok "REQ-E1-S03-01 cluster baseline Ready"
