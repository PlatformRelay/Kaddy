#!/usr/bin/env bash
# Idempotent bring-up of the kaddy-dev kind cluster + Cilium + cert-manager (E1e).
# Reuses a healthy existing cluster; recreates only if missing/unhealthy.
set -euo pipefail

CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${CLUSTER_DIR}/common.sh"

require_tools
detect_provider

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
  # --retain keeps a failed cluster for diagnostics; we delete+retry once.
  if ! kind create cluster \
      --name "${CLUSTER_NAME}" \
      --config "${CLUSTER_DIR}/kind/cluster.yaml" \
      --image "${KIND_NODE_IMAGE}" \
      --wait "${KIND_CLUSTER_WAIT}"; then
    log "kind create failed — deleting orphan and retrying once"
    kind delete cluster --name "${CLUSTER_NAME}" 2>/dev/null || true
    kind create cluster \
      --name "${CLUSTER_NAME}" \
      --config "${CLUSTER_DIR}/kind/cluster.yaml" \
      --image "${KIND_NODE_IMAGE}" \
      --wait "${KIND_CLUSTER_WAIT}"
  fi
  export_kubeconfig
  use_context
}

# NOTE: nodes stay NotReady until a CNI is installed — that is expected here
# because Cilium (installed next) IS the CNI. So we do NOT block on node Ready
# during initial create beyond kind's own control-plane wait.
create_cluster

bash "${CLUSTER_DIR}/install-cilium.sh"
bash "${CLUSTER_DIR}/install-cert-manager.sh"

log "cluster ${CLUSTER_NAME} up — Cilium + Gateway API + LB-IPAM + cert-manager ready"
kubectl get nodes -o wide >&2 || true
