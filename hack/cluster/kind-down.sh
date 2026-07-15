#!/usr/bin/env bash
# Tear down the kaddy-dev kind cluster (E1e). Idempotent.
set -euo pipefail

CLUSTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${CLUSTER_DIR}/common.sh"

require kind
detect_provider

if kind_cluster_exists; then
  log "deleting kind cluster ${CLUSTER_NAME}"
  kind delete cluster --name "${CLUSTER_NAME}"
else
  log "cluster ${CLUSTER_NAME} does not exist — nothing to delete"
fi
