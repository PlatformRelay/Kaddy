#!/usr/bin/env bash
# Install cert-manager (pinned v1.18.2) + the self-signed kaddy-local-ca ClusterIssuer (E1e S03).
set -euo pipefail

CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${CLUSTER_DIR}/common.sh"

require_tools
detect_provider
use_context
assert_kind_context

DEPLOY_DIR="${REPO_ROOT}/deploy/cluster-local"

log "installing cert-manager ${CERT_MANAGER_VERSION}"
helm repo add jetstack https://charts.jetstack.io >/dev/null 2>&1 || true
helm repo update jetstack >/dev/null 2>&1 || true

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --version "${CERT_MANAGER_VERSION}" \
  --set installCRDs=true \
  --wait --timeout "${HELM_TIMEOUT}"

log "waiting for cert-manager webhook"
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=180s

# The CA Certificate + ClusterIssuer. Retry apply because the webhook may take a
# moment to admit cert-manager.io resources after rollout reports Ready.
log "applying self-signed kaddy-local-ca ClusterIssuer"
for _ in $(seq 1 15); do
  if kubectl apply -f "${DEPLOY_DIR}/cluster-issuer.yaml" >/dev/null 2>&1; then
    break
  fi
  sleep 4
done
kubectl apply -f "${DEPLOY_DIR}/cluster-issuer.yaml"

log "waiting for kaddy-local-ca ClusterIssuer Ready"
for _ in $(seq 1 30); do
  if kubectl get clusterissuer kaddy-local-ca -o json 2>/dev/null \
      | jq -e '.status.conditions[]? | select(.type=="Ready") | .status=="True"' >/dev/null; then
    log "kaddy-local-ca is Ready"
    break
  fi
  sleep 4
done

log "cert-manager install complete"
