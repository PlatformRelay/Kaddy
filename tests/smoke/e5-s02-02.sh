#!/usr/bin/env bash
# REQ-E5-S02-02 (brief: HTTP response codes): the blackbox probe of the healthy
# clubhouse site reports probe_http_status_code == 200.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"
e5_prom_up

for _ in $(seq 1 24); do
  v="$(e5_prom_query 'max(probe_http_status_code{job="blackbox",service="clubhouse"})')"
  [[ "${v}" == "200" ]] && break
  sleep 5
done
[[ "${v:-}" == "200" ]] || smoke_fail "probe_http_status_code != 200 (got '${v:-none}')"
smoke_ok "REQ-E5-S02-02 — probe_http_status_code == 200"
