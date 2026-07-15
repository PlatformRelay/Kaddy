#!/usr/bin/env bash
# REQ-E4-S03-01: clubhouse Certificate reaches Ready=True.
# Kind-honest reinterpretation: issued by the in-cluster kaddy-local-ca ClusterIssuer
# (genuinely trusted). The spec's "staging issuer" wording targets Let's Encrypt
# staging, which cannot ISSUE on kind (no public HTTP-01) — that path is deferred /
# documented cloud-only (see deploy/cert-manager/clubhouse-certificate-letsencrypt.yaml).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

NS="gateway"
kubectl apply -f "${SMOKE_ROOT}/deploy/gateway/namespace.yaml" >/dev/null
kubectl apply -f "${SMOKE_ROOT}/deploy/cert-manager/clubhouse-certificate.yaml" >/dev/null

echo "waiting for clubhouse-tls Certificate Ready (kaddy-local-ca)"
kubectl -n "${NS}" wait --for=condition=Ready certificate/clubhouse-tls --timeout=120s \
  || smoke_fail "clubhouse-tls Certificate did not reach Ready=True"

# renewBefore configured -> cert-manager owns renewal (REQ-E4-S03-05).
rb="$(kubectl -n "${NS}" get certificate clubhouse-tls -o jsonpath='{.spec.renewBefore}' 2>/dev/null || true)"
[[ -n "${rb}" ]] || smoke_fail "clubhouse-tls Certificate missing spec.renewBefore (auto-renewal)"
smoke_ok "REQ-E4-S03-01 clubhouse Certificate Ready (renewBefore=${rb})"
