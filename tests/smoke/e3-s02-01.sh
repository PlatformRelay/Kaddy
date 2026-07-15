#!/usr/bin/env bash
# REQ-E3-S02-01: the Prometheus Operator ServiceMonitor CRD is Established.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster

echo "=== waiting for servicemonitors CRD Established ==="
kubectl wait --for=condition=Established --timeout=180s \
  crd/servicemonitors.monitoring.coreos.com \
  || smoke_fail "servicemonitors.monitoring.coreos.com CRD not Established"
smoke_ok "REQ-E3-S02-01 (ServiceMonitor CRD Established)"
