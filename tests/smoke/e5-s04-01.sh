#!/usr/bin/env bash
# REQ-E5-S04-01 (lab-reconciled): the Alertmanager receiver path works — a
# synthetic alert POSTed to the v2 API is accepted, routed and listed ACTIVE.
# External notification endpoints (ntfy/webhook) stay out of the lab (no
# secrets committed); the marshal fire demo proves the real Prometheus->AM leg.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"
e5_am_up
AM="http://127.0.0.1:${E5_AM_PORT:-29093}"

# Alertmanager healthy?
curl -sf "${AM}/-/healthy" >/dev/null || smoke_fail "Alertmanager not healthy"
smoke_ok "Alertmanager healthy"

# POST a synthetic, short-lived alert and read it back as active.
now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
end="$(date -u -v+2M +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '+2 minutes' +%Y-%m-%dT%H:%M:%SZ)"
payload="[{\"labels\":{\"alertname\":\"E5SmokeSynthetic\",\"severity\":\"info\",\"service\":\"monitoring\"},\"annotations\":{\"summary\":\"e5-s04-01 synthetic receiver-path check\"},\"startsAt\":\"${now}\",\"endsAt\":\"${end}\"}]"
code="$(curl -s -o /dev/null -w '%{http_code}' -XPOST -H 'Content-Type: application/json' \
  -d "${payload}" "${AM}/api/v2/alerts")"
[[ "${code}" == "200" ]] || smoke_fail "Alertmanager rejected the synthetic alert (HTTP ${code})"

sleep 2
n="$(curl -sf "${AM}/api/v2/alerts?filter=alertname%3D%22E5SmokeSynthetic%22&active=true" \
  | yq -p json 'length')"
[[ "${n}" =~ ^[1-9] ]] || smoke_fail "synthetic alert not ACTIVE in Alertmanager"
recv="$(curl -sf "${AM}/api/v2/alerts?filter=alertname%3D%22E5SmokeSynthetic%22&active=true" \
  | yq -p json '.[0].receivers[0].name // "?"')"
smoke_ok "REQ-E5-S04-01 — synthetic alert active, routed to receiver '${recv}'"
