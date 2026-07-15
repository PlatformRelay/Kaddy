#!/usr/bin/env bash
# REQ-E3-S03-01: letsencrypt-staging ClusterIssuer reaches Ready=True (ACME
# account registered against the staging directory — outbound-only, works on kind).
# REQ-E3-S03-02 note: letsencrypt-prod is also asserted PRESENT but documented as
# potentially not-Ready-on-kind; we only require staging Ready.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

echo "=== waiting for letsencrypt-staging ClusterIssuer Ready ==="
ready=""
for _ in $(seq 1 45); do
  ready="$(kubectl get clusterissuer letsencrypt-staging \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  [[ "${ready}" == "True" ]] && break
  sleep 5
done
[[ "${ready}" == "True" ]] \
  || smoke_fail "letsencrypt-staging not Ready (status='${ready:-none}')"
smoke_ok "letsencrypt-staging Ready=True"

# prod issuer must at least exist (manifest synced); Ready is not required on kind.
kubectl get clusterissuer letsencrypt-prod >/dev/null 2>&1 \
  || smoke_fail "letsencrypt-prod ClusterIssuer not present"
prod_ready="$(kubectl get clusterissuer letsencrypt-prod \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
echo "letsencrypt-prod present (Ready=${prod_ready:-unknown}; not required on kind)"

smoke_ok "REQ-E3-S03-01"
