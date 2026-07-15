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
smoke_ok "REQ-E1e-S02-03 LB-IPAM pool + L2 policy present"
