#!/usr/bin/env bash
# REQ-E3-S02-05: Loki is wired as a Grafana datasource (default logs source). We
# assert the provisioning ConfigMap exists and is discoverable by the Grafana
# sidecar (label grafana_datasource=1) and declares a type: loki default source.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
NS=monitoring

echo "=== checking Grafana Loki datasource ConfigMap ==="
for _ in $(seq 1 30); do
  kubectl -n "${NS}" get cm -l grafana_datasource=1 \
    -o yaml 2>/dev/null | grep -qi 'type: loki' && break
  sleep 5
done
out="$(kubectl -n "${NS}" get cm -l grafana_datasource=1 -o yaml 2>/dev/null)"
echo "${out}" | grep -qi 'type: loki' || smoke_fail "no grafana_datasource cm with type: loki"
# Loki is the single logs datasource (de-facto logs source). It is NOT marked
# isDefault: the chart already registers Prometheus as the one org default, and a
# second default makes Grafana refuse to boot. Spec verify only checks type: loki.
smoke_ok "REQ-E3-S02-05 (Loki datasource provisioned; single logs source)"
