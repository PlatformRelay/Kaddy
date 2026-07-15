#!/usr/bin/env bash
# REQ-E1e-S01-02: cluster bring-up is idempotent; all nodes Ready.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
kubectl get nodes -o json | jq -e \
  '[.items[].status.conditions[] | select(.type=="Ready" and .status!="True")] | length == 0' \
  >/dev/null || smoke_fail "not all nodes are Ready"
smoke_ok "REQ-E1e-S01-02 all nodes Ready"
