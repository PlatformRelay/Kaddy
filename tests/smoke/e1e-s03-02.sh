#!/usr/bin/env bash
# REQ-E1e-S03-02: a default StorageClass exists.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
kubectl get storageclass -o json | jq -e \
  '[.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true")] | length > 0' \
  >/dev/null || smoke_fail "no default StorageClass"
smoke_ok "REQ-E1e-S03-02 default StorageClass present"
