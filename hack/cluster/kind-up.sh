#!/usr/bin/env bash
# Idempotent bring-up of the kaddy-dev kind cluster + Cilium + cert-manager (E1e).
# Reuses a healthy existing cluster; recreates only if missing/unhealthy.
set -euo pipefail

CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${CLUSTER_DIR}/common.sh"

require_tools
detect_provider
assert_podman_rootful

create_cluster() {
  if kind_cluster_exists; then
    log "cluster ${CLUSTER_NAME} exists — verifying health"
    export_kubeconfig
    if use_context && kubectl wait --for=condition=Ready node --all --timeout=60s >/dev/null 2>&1; then
      log "reusing healthy cluster ${CLUSTER_NAME}"
      return 0
    fi
    log "cluster ${CLUSTER_NAME} unhealthy — recreating"
    kind delete cluster --name "${CLUSTER_NAME}"
  fi
  log "creating kind cluster ${CLUSTER_NAME} (image ${KIND_NODE_IMAGE})"
  # IMPORTANT: do NOT pass --wait here. With disableDefaultCNI the node stays
  # NotReady until Cilium (installed next) provides the CNI, so --wait would
  # always burn its full timeout. kind returns once the control-plane API is up;
  # we then wait for the API to answer before installing Cilium.
  if ! kind create cluster \
      --name "${CLUSTER_NAME}" \
      --config "${CLUSTER_DIR}/kind/cluster.yaml" \
      --image "${KIND_NODE_IMAGE}"; then
    log "kind create failed — deleting orphan and retrying once"
    kind delete cluster --name "${CLUSTER_NAME}" 2>/dev/null || true
    kind create cluster \
      --name "${CLUSTER_NAME}" \
      --config "${CLUSTER_DIR}/kind/cluster.yaml" \
      --image "${KIND_NODE_IMAGE}"
  fi
  export_kubeconfig
  use_context
}

# NOTE: nodes stay NotReady until a CNI is installed — that is expected here
# because Cilium (installed next) IS the CNI. So we block only on the API server
# answering, not on node Ready, before handing off to the Cilium installer.
create_cluster

log "waiting for the kaddy-dev API server to answer"
for _ in $(seq 1 30); do
  if kubectl version >/dev/null 2>&1 && kubectl get --raw='/readyz' >/dev/null 2>&1; then
    break
  fi
  sleep 4
done
kubectl get --raw='/readyz' >/dev/null 2>&1 || fail "API server did not become ready"

bash "${CLUSTER_DIR}/install-cilium.sh"
bash "${CLUSTER_DIR}/install-cert-manager.sh"

log "cluster ${CLUSTER_NAME} up — Cilium + Gateway API + LB-IPAM + cert-manager ready"
kubectl get nodes -o wide >&2 || true
