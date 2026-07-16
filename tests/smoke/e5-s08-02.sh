#!/usr/bin/env bash
# REQ-E5-S08-02 (operator req 2026-07-16): the marshal alerts surface in Grafana
# as DATA-SOURCE-MANAGED alerting — evaluated by the Prometheus ruler
# (PrometheusRule CRs), read by Grafana through the Prometheus datasource rules
# API (/api/prometheus/<ds-uid>/api/v1/rules). NOT Grafana-managed (UI-clicked)
# rules: we additionally assert the marshal group is absent from the
# Grafana-managed ruler namespace list.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"
e5_grafana_up
e5_grafana_creds
G="http://127.0.0.1:${E5_GRAFANA_PORT:-13000}"
AUTH=(-u "${E5_GRAFANA_USER}:${E5_GRAFANA_PASS}")

# Resolve the provisioned Prometheus datasource UID (don't assume).
ds_uid="$(curl -sf "${AUTH[@]}" "${G}/api/datasources" \
  | yq -p json '.[] | select(.type == "prometheus") | .uid' | head -1)"
[[ -n "${ds_uid}" ]] || smoke_fail "no Prometheus datasource provisioned in Grafana"
smoke_ok "Prometheus datasource uid=${ds_uid}"

# Data-source-managed rules: Grafana proxies the Prometheus ruler API.
curl -sf "${AUTH[@]}" "${G}/api/prometheus/${ds_uid}/api/v1/rules" -o /tmp/e5-ds-rules.json \
  || smoke_fail "Grafana datasource rules endpoint failed"
group="$(yq -p json '.data.groups[] | select(.name == "marshal.http") | .name' /tmp/e5-ds-rules.json)"
[[ "${group}" == "marshal.http" ]] \
  || smoke_fail "marshal.http group not visible via Grafana data-source-managed alerting"

for a in ClubhouseDown ClubhouseProbeLatencyHigh ClubhouseCertExpirySoon EdgeHTTPErrorRate EdgeRequestRateHigh; do
  yq -p json -e ".data.groups[] | select(.name == \"marshal.http\") | .rules[] | select(.name == \"${a}\") | .name" \
    /tmp/e5-ds-rules.json >/dev/null \
    || smoke_fail "alert ${a} missing from the data-source-managed marshal.http group"
  echo "OK   ${a} visible (data-source-managed)"
done

# Negative assertion: these are NOT Grafana-managed rules.
gm="$(curl -sf "${AUTH[@]}" "${G}/api/prometheus/grafana/api/v1/rules" \
  | yq -p json '[.data.groups[]? | select(.name == "marshal.http")] | length' 2>/dev/null || echo 0)"
[[ "${gm}" == "0" ]] || smoke_fail "marshal.http unexpectedly present as Grafana-MANAGED rules"
smoke_ok "REQ-E5-S08-02 — marshal alerts are data-source-managed in Grafana (not UI-managed)"
