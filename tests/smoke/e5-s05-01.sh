#!/usr/bin/env bash
# REQ-E5-S05-01 / REQ-E5-S08-01: the kaddy-marshal dashboard is provisioned AS
# CODE — the sidecar-labelled ConfigMap exists and Grafana serves dashboard UID
# `kaddy-marshal` via /api/dashboards/uid/ with the expected panels.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"

kubectl -n monitoring get configmap kaddy-marshal-dashboard \
  -o jsonpath='{.metadata.labels.grafana_dashboard}' | grep -qx "1" \
  || smoke_fail "kaddy-marshal-dashboard ConfigMap missing sidecar label grafana_dashboard=1"
smoke_ok "dashboard ConfigMap present with sidecar label"

e5_grafana_up
e5_grafana_creds
G="http://127.0.0.1:${E5_GRAFANA_PORT:-23000}"

# The sidecar needs a moment after the CM lands; poll briefly.
found=""
for _ in $(seq 1 30); do
  if curl -sf -u "${E5_GRAFANA_USER}:${E5_GRAFANA_PASS}" "${G}/api/dashboards/uid/kaddy-marshal" \
      -o /tmp/e5-dashboard.json 2>/dev/null; then
    found=1; break
  fi
  sleep 4
done
[[ -n "${found}" ]] || smoke_fail "Grafana has no dashboard with uid kaddy-marshal"

title="$(yq -p json '.dashboard.title' /tmp/e5-dashboard.json)"
panels="$(yq -p json '.dashboard.panels | length' /tmp/e5-dashboard.json)"
[[ "${panels}" -ge 10 ]] || smoke_fail "kaddy-marshal dashboard has only ${panels} panels"
smoke_ok "REQ-E5-S05-01 — Grafana serves '${title}' (uid kaddy-marshal, ${panels} panels)"
