#!/usr/bin/env bash
# REQ-E3-S03-00: cert-manager controller installed (E1e) — assert Available.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

echo "=== asserting cert-manager Deployments Available ==="
kubectl wait --for=condition=Available deployment -n cert-manager --all --timeout=180s \
  || smoke_fail "cert-manager deployments not all Available"

for crd in clusterissuers.cert-manager.io issuers.cert-manager.io certificates.cert-manager.io; do
  kubectl get crd "${crd}" >/dev/null 2>&1 || smoke_fail "CRD ${crd} missing"
done
smoke_ok "REQ-E3-S03-00 (cert-manager Available)"
