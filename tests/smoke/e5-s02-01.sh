#!/usr/bin/env bash
# REQ-E5-S02-01: the blackbox HTTPS probe of the live clubhouse site through the
# Cilium Gateway succeeds — probe_success == 1 (CA-verified TLS, SNI/Host pinned
# to clubhouse.kaddy.local).
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${DIR}/lib.sh"
smoke_require_cluster
# shellcheck disable=SC1091
source "${DIR}/e5-lib.sh"
e5_prom_up

# Allow a fresh probe cycle (interval 15s) to land.
for _ in $(seq 1 24); do
  v="$(e5_prom_query 'min(probe_success{job="blackbox",service="clubhouse"})')"
  [[ "${v}" == "1" ]] && break
  sleep 5
done
[[ "${v:-}" == "1" ]] || smoke_fail "probe_success != 1 (got '${v:-none}') — clubhouse probe failing"
smoke_ok "REQ-E5-S02-01 — probe_success == 1 for the clubhouse site"
