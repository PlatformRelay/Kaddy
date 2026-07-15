#!/usr/bin/env bash
# REQ-E3-S02-02: Prometheus and Alertmanager pods Running in ns monitoring (an
# alert CAN fire — the spine is live). Waits on the operator-managed pods by their
# well-known labels.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
NS=monitoring

echo "=== waiting for Prometheus pod Ready ==="
kubectl wait -n "${NS}" --for=condition=Ready pod \
  -l app.kubernetes.io/name=prometheus --timeout=300s \
  || smoke_fail "Prometheus pod not Ready in ns ${NS}"
smoke_ok "Prometheus Running/Ready"

echo "=== waiting for Alertmanager pod Ready ==="
kubectl wait -n "${NS}" --for=condition=Ready pod \
  -l app.kubernetes.io/name=alertmanager --timeout=300s \
  || smoke_fail "Alertmanager pod not Ready in ns ${NS}"
smoke_ok "Alertmanager Running/Ready"

smoke_ok "REQ-E3-S02-02"
