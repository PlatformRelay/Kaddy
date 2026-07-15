#!/usr/bin/env bash
# REQ-E3-S02-03: Loki (single-binary + filesystem) is Ready in ns monitoring.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
NS=monitoring

echo "=== waiting for Loki pod Ready ==="
kubectl wait -n "${NS}" --for=condition=Ready pod \
  -l app.kubernetes.io/name=loki --timeout=300s \
  || smoke_fail "Loki pod not Ready in ns ${NS}"

# Assert it really is the single-binary topology (exactly one Loki pod).
count="$(kubectl -n "${NS}" get pods -l app.kubernetes.io/name=loki \
  --no-headers 2>/dev/null | wc -l | tr -d ' ')"
[[ "${count}" == "1" ]] || smoke_fail "expected 1 Loki pod (single-binary), found ${count}"
smoke_ok "REQ-E3-S02-03 (Loki single-binary Ready)"
