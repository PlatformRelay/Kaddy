#!/usr/bin/env bash
# REQ-E5-S02-03: the blackbox exporter is GitOps-deployed and its CA trust chain
# converged declaratively — the kaddy-ca-trust Certificate is Ready (cert-manager
# wrote ca.crt into the Secret) and the exporter Deployment is Available.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
NS=monitoring

kubectl -n "${NS}" wait --for=condition=Ready certificate/kaddy-ca-trust --timeout=120s \
  || smoke_fail "kaddy-ca-trust Certificate not Ready (CA courier for blackbox TLS trust)"
kubectl -n "${NS}" get secret kaddy-ca-trust -o jsonpath='{.data.ca\.crt}' | grep -q . \
  || smoke_fail "kaddy-ca-trust Secret has no ca.crt key"
smoke_ok "kaddy-ca-trust CA courier Ready (ca.crt present)"

kubectl -n "${NS}" wait --for=condition=Available deploy/blackbox-exporter --timeout=180s \
  || smoke_fail "blackbox-exporter Deployment not Available"
smoke_ok "blackbox-exporter Deployment Available"

kubectl -n "${NS}" get probe clubhouse >/dev/null \
  || smoke_fail "Probe monitoring/clubhouse missing"
smoke_ok "REQ-E5-S02-03 — blackbox exporter + Probe + CA trust live via GitOps"
